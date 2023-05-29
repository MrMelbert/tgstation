GLOBAL_LIST_INIT(attack_styles, init_attack_styles())

/proc/init_attack_styles()
	var/list/styles = list()
	for(var/style_type in subtypesof(/datum/attack_style))
		styles[style_type] = new style_type()

	return styles

/datum/movespeed_modifier/attack_style_executed
	variable = TRUE

/**
 * # Attack style singleton
 *
 * Handles sticking behavior onto a weapon to make it attack a certain way
 */
/datum/attack_style
	/// Hitsound played on a successful attack hit
	/// If null, uses item hitsound.
	var/successful_hit_sound
	/// Volume of hitsound
	var/hit_volume = 50
	/// Hitsound played on if the attack fails to hit anyone
	var/miss_sound = 'sound/weapons/fwoosh.ogg'
	/// Volume of miss sound
	var/miss_volume = 50
	/// Click CD imparted by successful attacks
	/// Failed attacks still apply a click CD, but reduced
	var/cd = CLICK_CD_MELEE
	/// Movement slowdown applied on an attack
	var/slowdown = 1
	/// The number of mobs that can be hit per hit turf
	var/hits_per_turf_allowed = 1
	/// How long does it take for the attack to travel between turfs?
	/// Essentually, this is "swing speed". Does nothing for attacks which only hit a single turf.
	var/time_per_turf = 0 SECONDS

/**
 * Process attack -> execute attack -> finalize attack
 *
 * Arguments
 * * attacker - the mob doing the attack
 * * weapon - optional, the item being attacked with.
 * * aimed_towards - what atom the attack is being aimed at, does not necessarily correspond to the atom being attacked,
 * but is also checked as a priority target if multiple mobs are on the same turf.
 * * right_clicking - whether the attack was done via r-click
 *
 * Implementation notes
 * * Do not override process attack
 * * You may extend execute attack with additonal checks, but call parent
 * * You can freely override finalize attack with whatever behavior you want
 *
 * Usage notes
 * * Does NOT check for nextmove, that should be checked before entering this
 * * DOES check for pacifism
 *
 * Return TRUE on success, and FALSE on failure
 */
/datum/attack_style/proc/process_attack(mob/living/attacker, obj/item/weapon, atom/aimed_towards, right_clicking = FALSE)
	SHOULD_NOT_OVERRIDE(TRUE)

	weapon?.add_fingerprint(attacker)
	if(HAS_TRAIT(attacker, TRAIT_PACIFISM) && check_pacifism(attacker, weapon))
		attacker.balloon_alert(attacker, "you don't want to attack!")
		return FALSE

	if(IS_BLOCKING(attacker))
		attacker.balloon_alert(attacker, "can't act while blocking!")
		return FALSE

	// This gives a little bit of leeway for angling attacks.
	// If we straight up use dir, then the window for doing a NSEW attack is far smaller than the window for NE/SE/SW/NW attacks.
	// But by using angle, we can use a slightly larger and equal range for all angles, each being 45 degrees.
	var/attack_direction = NONE
	var/click_angle = get_angle(attacker, aimed_towards)
	switch(click_angle)
		if(0 to 22.5, 337.5 to 360)
			attack_direction = NORTH
		if(22.5 to 67.5)
			attack_direction = NORTHEAST
		if(67.5 to 112.5)
			attack_direction = EAST
		if(112.5 to 157.5)
			attack_direction = SOUTHEAST
		if(157.5 to 202.5)
			attack_direction = SOUTH
		if(202.5 to 247.5)
			attack_direction = SOUTHWEST
		if(247.5 to 292.5)
			attack_direction = WEST
		if(292.5 to 337.5)
			attack_direction = NORTHWEST
		else
			// ??? result, just default to dir
			stack_trace("[attacker] clicking on [aimed_towards] resulted in invalid angle [click_angle].")
			attack_direction = get_dir(attacker, aimed_towards)

	var/list/affecting = select_targeted_turfs(attacker, attack_direction, right_clicking)

	// Make sure they don't move while swinging
	var/pre_set_dir = attacker.set_dir_on_move
	attacker.set_dir_on_move = FALSE
	// Make sure they can't attack while swinging
	attacker.changeNext_move(time_per_turf * length(affecting))
	// Prioritise the atom we clicked on initially, so if two mobs are on one turf, we hit the one we clicked on
	var/attack_result = execute_attack(attacker, weapon, affecting, aimed_towards, right_clicking)
	// Restore this
	attacker.set_dir_on_move = pre_set_dir
	// Check the result.
	if(attack_result & ATTACK_STYLE_CANCEL)
		// Just apply a small second CD so they don't spam failed attacks
		attacker.changeNext_move(0.33 SECONDS)
		return FALSE

	if(slowdown > 0)
		attacker.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/attack_style_executed, multiplicative_slowdown = slowdown)
		addtimer(CALLBACK(attacker, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/attack_style_executed), cd * 0.2)
	if(cd > 0)
		attacker.changeNext_move(cd)
	return TRUE

/datum/attack_style/proc/execute_attack(mob/living/attacker, obj/item/weapon, list/turf/affecting, atom/priority_target, right_clicking)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	attack_effect_animation(attacker, weapon, affecting)

	// This is storing the flag to return when the attack is finished executing
	var/attack_flag = NONE
	// The total number of mobs hit across all turfs (where "total_hit" is the total hit on a single turf)
	var/total_total_hit = 0
	// The index of the turf we're currently hitting
	var/affecting_index = 1
	// The midpoint of the affected turf list
	var/midpoint = ROUND_UP(length(affecting) / 2)
	// This tracks if this attack was initiated with a weapon,
	// so we can check if it's still being held for swings that have travel time
	var/started_holding = !isnull(weapon) && attacker.is_holding(weapon)
	// This tracks the loc the swing started at,
	// so we can re-generate the affecting turfs list for swings that have travel time if the attacker moves
	var/turf/starting_loc = attacker.loc
	// A list of mobs that have already been hit by this attack to prevent double dipping
	var/list/mob/living/already_hit = list()
	// Tracks whether a hitsound has been played,
	// primarily for attacks with travel time so a hit is played on first strike
	var/hitsound_played = FALSE
	// The dir the attacker was facing when the attack started,
	// so changing dir mid swing for attacks with travel time don't change the direction of the attack
	var/starting_dir = attacker.dir

	// Main attack loop starts here.
	while(length(affecting))
		var/turf/hitting = popleft(affecting)
		// - The midpoint is always hitable, this isn't very "sensible" but if this wasn't the case
		// one would be completely immune to being attacked by standing on a dense object.
		// - The first turf is always hitable, for similar reasons to above.
		// - Every other turf, though, will block ongoing swings.
		// Unfortunately this robs us of some cool interactions like not being able to fight in a 1 wide hallways
		// with a wide arc weapon like a baseball bat, but maybe it's for the better?
		if(affecting_index != 1 && affecting_index != midpoint)
			var/atom/blocking_us = hitting.is_blocked_turf(exclude_mobs = TRUE, source_atom = attacker)
			if(blocking_us)
				attacker.visible_message(
					span_warning("[attacker]'s attack collides with [blocking_us]!"),
					span_warning("[blocking_us] blocks your attack partway!"),
				)
				if(blocking_us.uses_integrity)
					log_combat(attacker, blocking_us, "hit mid-swing", weapon)
					blocking_us.take_damage(weapon.force, weapon.damtype, MELEE, TRUE,
						get_dir(attacker, blocking_us), weapon.armour_penetration)
				else
					blocking_us.play_attack_sound(weapon.force, weapon.damtype, MELEE)

				return attack_flag || ATTACK_STYLE_CANCEL // Purposeful use of || and not |, only sends CANCEL if no flags are set

#ifdef TESTING
		apply_testing_color(hitting, affecting_index)
#endif

		affecting_index += 1

		// Gathers up all mobs in the turf being struck. Each mob will have a priority assigned.
		// Intuitively an attacker will not want to attack certain mobs, such as their friends, or unconscious people over conscious people.
		// While this doesn't completley mitigate the chance of friendly fire, it does make it less likely.
		var/list/mob/living/foes = list()
		for(var/mob/living/foe_in_turf in hitting)
			if(foe_in_turf in already_hit)
				continue

			var/foe_prio = rand(4, 8) // assign a random priority so it's non-deterministic
			if(foe_in_turf == priority_target)
				foe_prio = 10
			else if(foe_in_turf == attacker)
				foe_prio = -10
			else if(foe_in_turf.stat != CONSCIOUS)
				foe_prio = 2 // very de-prio folk who can't fight back

			if(length(foe_in_turf.faction & attacker.faction))
				foe_prio -= 2 // de-prio same factions

			foes[foe_in_turf] = foe_prio

		// Sorts by priority
		sortTim(foes, cmp = /proc/cmp_numeric_dsc, associative = TRUE)

		var/total_hit = 0
		// Here is where we go into finalize attack, to actually cause damage.
		// This is where attack swings enter attack chain.
		for(var/mob/living/smack_who as anything in foes)
			already_hit += smack_who
			var/new_results = finalize_attack(attacker, smack_who, weapon, right_clicking)
			if(!(new_results & ATTACK_STYLE_HIT))
				continue
			attack_flag |= new_results
			total_hit++
			if(total_hit >= hits_per_turf_allowed)
				break

		total_total_hit += total_hit
		// Immediately check if the attack was cancelled from the attack chain.
		// Cancel = completely stop everything, return no other flags, do not pass go, do not collect $200.
		if(attack_flag & ATTACK_STYLE_CANCEL)
			return ATTACK_STYLE_CANCEL
		// A hit or block was made, so we can play a hitsound if one is set.
		if(attack_flag & (ATTACK_STYLE_HIT|ATTACK_STYLE_BLOCKED))
			if(!hitsound_played)
				hitsound_played = TRUE
				var/hitsound_to_use = get_hit_sound(weapon)
				if(hitsound_to_use)
					playsound(attacker, hitsound_to_use, hit_volume, TRUE)
			// However, if the attack was a block and not a hit, we stop at this turf.
			if(attack_flag & ATTACK_STYLE_BLOCKED)
				break

		// Finally, we handle travel time.
		if(time_per_turf > 0 && affecting_index != 1 && length(affecting))
			stoplag(time_per_turf)
			// Sanity checking
			if(QDELETED(attacker))
				return ATTACK_STYLE_CANCEL
			if(started_holding && (QDELETED(weapon) || !attacker.is_holding(weapon)))
				return ATTACK_STYLE_CANCEL
			if(attacker.incapacitated())
				return ATTACK_STYLE_CANCEL
			if(attacker.loc != starting_loc)
				if(!isturf(attacker.loc))
					return ATTACK_STYLE_CANCEL

				// At this point we've moved a turf but can continue attacking, so we'll
				// soft restart the swing from this point at the new turf.
				starting_loc = attacker.loc
				affecting = select_targeted_turfs(attacker, starting_dir, right_clicking)
				affecting.Cut(1, affecting_index)

	// All relevant turfs have been hit so we're wrapping up the attack at this point

	if(total_total_hit <= 0)
		// counts as a miss if we don't hit anyone, duh
		attack_flag |= ATTACK_STYLE_MISSED

	if(attack_flag & ATTACK_STYLE_MISSED)
		if(miss_sound)
			playsound(attacker, miss_sound, miss_volume, TRUE)

	return attack_flag

/**
 * Gets the soound to play when the attack successfully hits another mob
 *
 * * weapon - The weapon being used, can be null or a non-held item depending on the attack style
 */
/datum/attack_style/proc/get_hit_sound(obj/item/weapon)
	return successful_hit_sound || weapon?.hitsound

/**
 * Used to determine what turfs this attack is going to hit when executed.
 *
 * * attacker - The mob doing the attacking
 * * attack_direction - The direction the attack is coming from
 * * right_clicking - Whether the attack was initiated via right click
 *
 * Return a list of turfs with nulls filtered out
 */
/datum/attack_style/proc/select_targeted_turfs(mob/living/attacker, attack_direction, right_clicking)
	RETURN_TYPE(/list)
	return list(get_step(attacker, attack_direction))

/**
 * Called when the attacker has the pacifism trait.
 *
 * * attacker - The mob doing the attacking
 * * weapon - The weapon being used, can be null or a non-held item depending on the attack style
 *
 * Return TRUE to stop the attack
 * Return FALSE to allow the attack
 */
/datum/attack_style/proc/check_pacifism(mob/living/attacker, obj/item/weapon)
	return FALSE

/**
 * Plays an animation for the attack.
 *
 * * attacker - The mob doing the attacking
 * * weapon - The weapon being used, can be null or a non-held item depending on the attack style
 * * affecting - The list of turfs being affected by the attack
 */
/datum/attack_style/proc/attack_effect_animation(mob/living/attacker, obj/item/weapon, list/turf/affecting)
	attacker.do_attack_animation(get_movable_to_layer_effect_over(affecting))

/// Can be used in [proc/attack_effect_animation] to select some atom
/// in the list of affecting turfs to play the attack animation over
/datum/attack_style/proc/get_movable_to_layer_effect_over(list/turf/affecting)
	var/turf/midpoint = affecting[ROUND_UP(length(affecting) / 2)]
	for(var/atom/movable/thing in midpoint)
		if(isProbablyWallMounted(thing))
			continue
		if(thing.invisibility > 0 || thing.alpha < 10)
			continue
		return thing

	return midpoint

/**
 * Finalize an attack on a single mob in one of the affected turfs
 *
 * * attacker - The mob doing the attacking
 * * smacked - The mob being attacked
 * * weapon - The weapon being used, can be null or a non-held item depending on the attack style
 * * right_clicking - Whether the attack was initiated via right click
 */
/datum/attack_style/proc/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	PROTECTED_PROC(TRUE)
	return

#ifdef TESTING
/datum/attack_style/proc/apply_testing_color(turf/hit, index = -1)
	hit.add_atom_colour(COLOR_RED, TEMPORARY_COLOUR_PRIORITY)
	hit.maptext = MAPTEXT("[index]")
	animate(hit, 1 SECONDS, color = null)
	addtimer(CALLBACK(src, PROC_REF(clear_testing_color), hit), 1 SECONDS)
#endif

#ifdef TESTING
/datum/attack_style/proc/clear_testing_color(turf/hit)
	hit.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_RED)
	hit.maptext = null
#endif

/datum/attack_style/melee_weapon
	/// The attack effect is scaled by this amount
	var/sprite_size_multiplier = 1

/datum/attack_style/melee_weapon/check_pacifism(mob/living/attacker, obj/item/weapon)
	return weapon.force > 0

/datum/attack_style/melee_weapon/proc/get_swing_description()
	return "It swings at one tile in the direction you are attacking."

/datum/attack_style/melee_weapon/execute_attack(mob/living/attacker, obj/item/weapon, list/turf/affecting, atom/priority_target, right_clicking)
	ASSERT(istype(weapon))
	return ..()

/// This is essentially the same as item melee attack chain, but with some guff not necessary for combat cut out.
/datum/attack_style/melee_weapon/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	. = NONE

	var/go_to_attack = !right_clicking
	if(right_clicking)
		switch(weapon.pre_attack_secondary(smacked, attacker))
			if(SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
				return ATTACK_STYLE_CANCEL
			if(SECONDARY_ATTACK_CALL_NORMAL)
				// pass()
			if(SECONDARY_ATTACK_CONTINUE_CHAIN)
				go_to_attack = TRUE
			else
				CRASH("pre_attack_secondary must return an SECONDARY_ATTACK_* define, please consult code/__DEFINES/combat.dm")

	if(go_to_attack && weapon.pre_attack(smacked, attacker))
		return . | ATTACK_STYLE_CANCEL

	var/go_to_afterattack = !right_clicking
	if(right_clicking)
		switch(weapon.attack_secondary(smacked, attacker))
			if(SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
				return ATTACK_STYLE_CANCEL
			if(SECONDARY_ATTACK_CALL_NORMAL)
				// pass()
			if(SECONDARY_ATTACK_CONTINUE_CHAIN)
				go_to_afterattack = TRUE
			else
				CRASH("attack_secondary must return an SECONDARY_ATTACK_* define, please consult code/__DEFINES/combat.dm")

	if(go_to_afterattack && weapon.attack_wrapper(smacked, attacker))
		return . | ATTACK_STYLE_CANCEL

	smacked.lastattacker = attacker.real_name
	smacked.lastattackerckey = attacker.ckey

	if(attacker == smacked && attacker.client)
		attacker.client.give_award(/datum/award/achievement/misc/selfouch, attacker)

	// !! ACTUAL DAMAGE GETS APPLIED HERE !!
	. |= smacked.attacked_by(weapon, attacker)
	log_combat(attacker, smacked, "attacked", weapon.name, "(STYLE: [type]) (DAMTYPE: [uppertext(weapon.damtype)])")

	// Any of these flags means there is no after attack
	if(. & (ATTACK_STYLE_BLOCKED|ATTACK_STYLE_CANCEL|ATTACK_STYLE_SKIPPED))
		return .

	if(right_clicking)
		switch(weapon.afterattack_secondary(smacked, attacker, /* proximity_flag = */TRUE))
			if(SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
				return . | ATTACK_STYLE_CANCEL
			if(SECONDARY_ATTACK_CALL_NORMAL)
				// pass()
			if(SECONDARY_ATTACK_CONTINUE_CHAIN)
				return .
			else
				CRASH("afterattack_secondary must return an SECONDARY_ATTACK_* define, please consult code/__DEFINES/combat.dm")

	// Don't really care about the return value of after attack.
	weapon.afterattack(smacked, attacker, /* proximity_flag = */TRUE)
	return .

/// Creates an image for use in attack animations
/datum/attack_style/melee_weapon/proc/create_attack_image(mob/living/attacker, obj/item/weapon, turf/initial_loc, angle)
	if(isnull(angle))
		angle = -weapon.weapon_sprite_angle + get_angle(attacker, initial_loc)

	var/image/attack_image = image(icon = weapon, loc = attacker, layer = attacker.layer + 0.1)
	attack_image.transform = turn(attack_image.transform, angle)
	attack_image.transform *= sprite_size_multiplier
	attack_image.pixel_x = (initial_loc.x - attacker.x) * 16
	attack_image.pixel_y = (initial_loc.y - attacker.y) * 16
	return attack_image

/**
 * Unarmed attack styles work slightly differently
 *
 * For normal attack styles, the style should not be handling the damage whatsoever, it should be handled by the weapon.
 *
 * But since we have no weapon for these, we kinda hvae to do it ourselves.
 */
/datum/attack_style/unarmed
	successful_hit_sound = 'sound/weapons/punch1.ogg'
	miss_sound = 'sound/weapons/punchmiss.ogg'

	/// Used for playing a little animation over the turf
	var/attack_effect = ATTACK_EFFECT_PUNCH

/datum/attack_style/unarmed/check_pacifism(mob/living/attacker, obj/item/weapon)
	return FALSE

/datum/attack_style/unarmed/execute_attack(mob/living/attacker, obj/item/bodypart/weapon, list/turf/affecting, atom/priority_target, right_clicking)
	ASSERT(isnull(weapon) || istype(weapon, /obj/item/bodypart))
	return ..()

/datum/attack_style/unarmed/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("No unarmed interaction for [type]!")

/datum/attack_style/unarmed/attack_effect_animation(mob/living/attacker, obj/item/bodypart/weapon, list/turf/affecting, override_effect)
	var/selected_effect = override_effect || attack_effect
	if(selected_effect)
		attacker.do_attack_animation(get_movable_to_layer_effect_over(affecting), selected_effect)
