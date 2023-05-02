GLOBAL_LIST_INIT(attack_styles, init_attack_styles())

/proc/init_attack_styles()
	var/list/styles = list()
	for(var/style_type in typesof(/datum/attack_style))
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
	var/execute_sound = 'sound/weapons/fwoosh.ogg'
	var/cd = CLICK_CD_MELEE
	var/slowdown = 1
	var/reverse_for_lefthand = TRUE

/datum/attack_style/proc/process_attack(mob/living/attacker, obj/item/weapon, atom/aimed_towards, right_clicking = FALSE)
	var/attack_direction = get_dir(attacker, get_turf(aimed_towards))
	var/list/affecting = select_targeted_turfs(attacker, attack_direction, right_clicking)
	if(reverse_for_lefthand)
		// Determine which hand the attacker is attacking from
		// If they are not holding the weapon passed / the weapon is null, default to active hand
		var/which_hand = (!isnull(weapon) && attacker.get_held_index_of_item(weapon)) || attacker.active_hand_index

		// Left hand will reverse the turfs list order
		if(which_hand % 2 == 1)
			reverse_range(affecting)

	// Prioritise the atom we clicked on initially, so if two mobs are on one turf, we hit the one we clicked on
	if(!execute_attack(attacker, weapon, affecting, right_clicking, priority_target = aimed_towards))
		return FALSE

	if(slowdown > 0)
		attacker.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/attack_style_executed, multiplicative_slowdown = slowdown)
		addtimer(CALLBACK(attacker, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/attack_style_executed), cd * 0.2)
	if(cd > 0)
		attacker.changeNext_move(cd)
	return TRUE

/datum/attack_style/proc/execute_attack(mob/living/attacker, obj/item/weapon, list/affecting, right_clicking, atom/priority_target)
	SHOULD_CALL_PARENT(TRUE)

	attack_effect_animation(attacker, weapon, affecting)

	for(var/turf/hitting as anything in affecting)
		if(isliving(priority_target) && (priority_target in hitting))
			weapon.attack(priority_target, attacker)
			break
		for(var/mob/living/smacked in hitting)
			weapon.attack(smacked, attacker)
			break

#ifdef TESTING
		apply_testing_color(hitting, affecting.Find(hitting))
#endif

	if(execute_sound)
		playsound(attacker, execute_sound, 50, TRUE)
	return TRUE

#ifdef TESTING
/datum/attack_style/proc/apply_testing_color(turf/hit, index = -1)
	hit.add_atom_colour(COLOR_RED, TEMPORARY_COLOUR_PRIORITY)
	hit.maptext = MAPTEXT("[index]")
	animate(hit, 1 SECONDS, color = null)
	addtimer(CALLBACK(src, PROC_REF(clear_testing_color), hit), 1 SECONDS)

/datum/attack_style/proc/clear_testing_color(turf/hit)
	hit.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_RED)
	hit.maptext = null
#endif

/datum/attack_style/proc/select_targeted_turfs(mob/living/attacker, attack_direction, right_clicking)
	RETURN_TYPE(/list)
	return list(get_step(attacker, attack_direction))

/datum/attack_style/proc/attack_effect_animation(mob/living/attacker, obj/item/weapon, list/affecting)
	return

/**
 * Not necessarily an attack style, but essentialy this allows you to have item specific interations
 * for clicking on atoms.
 *
 * Set your item to use this rather than any other attack style and it will execute an item level proc instead.
 */
/datum/attack_style/item_iteraction

/datum/attack_style/item_iteraction/process_attack(mob/living/attacker, obj/item/weapon, atom/aimed_towards, right_clicking)
	var/close_enough = attacker.CanReach(aimed_towards, weapon)
	if(close_enough)
		. = weapon.special_click_on_melee(attacker, aimed_towards, right_clicking)
	else
		. = weapon.special_click_on_range(attacker, aimed_towards, right_clicking)

	return .

// swings at 3 targets in a direction
/datum/attack_style/swing
	cd = CLICK_CD_MELEE * 3 // Three times the turfs, 3 times the cooldown

/datum/attack_style/swing/select_targeted_turfs(mob/living/attacker, attack_direction, right_clicking)
	return get_turfs_and_adjacent_in_direction(attacker, attack_direction)

/datum/attack_style/swing/requires_wield

/datum/attack_style/swing/requires_wield/execute_attack(mob/living/attacker, obj/item/weapon, list/affecting, atom/priority_target)
	if(!HAS_TRAIT(weapon, TRAIT_WIELDED))
		return FALSE
	return ..()

/datum/attack_style/swing/esword
	cd = CLICK_CD_MELEE * 1.25 // Much faster than normal swings
	reverse_for_lefthand = FALSE

/datum/attack_style/swing/esword/execute_attack(mob/living/attacker, obj/item/melee/energy/weapon, list/affecting, right_clicking, atom/priority_target)
	if(!weapon.blade_active)
		return FALSE

	// Right clicking attacks the opposite direction
	if(right_clicking)
		reverse_range(affecting)

	return ..()

/datum/attack_style/swing/requires_wield/desword
	cd = CLICK_CD_MELEE * 1.25
	reverse_for_lefthand = FALSE

/datum/attack_style/swing/requires_wield/desword/select_targeted_turfs(mob/living/attacker, attack_direction, right_clicking)
	// todo: make this do an aoe around.
	return ..()

// Direct stabs out to turfs in front
/datum/attack_style/stab_out
	reverse_for_lefthand = FALSE
	var/stab_range = 1

/datum/attack_style/stab_out/select_targeted_turfs(mob/living/attacker, attack_direction, right_clicking)
	var/max_range = stab_range
	var/turf/last_turf = get_turf(attacker)
	var/list/select_turfs = list()
	while(max_range > 0)
		var/turf/next_turf = get_step(last_turf, attack_direction)
		if(!isturf(next_turf) || next_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = attacker))
			return select_turfs
		select_turfs += next_turf
		last_turf = next_turf
		max_range--

	return select_turfs

/datum/attack_style/stab_out/spear
	cd = CLICK_CD_MELEE * 2
	stab_range = 2

/datum/attack_style/stab_out/spear/execute_attack(mob/living/attacker, obj/item/weapon, list/affecting, atom/priority_target)
	if(!HAS_TRAIT(weapon, TRAIT_WIELDED))
		return FALSE
	return ..()

// Overhead swings, bypass blocks / targets heads
/datum/attack_style/overhead
