// Cleaving saw

/// Helper for checking if a cleaving saw is open
#define SAW_OPEN(saw) (HAS_TRAIT(saw, TRAIT_TRANSFORM_ACTIVE))
/// Helper for checking if a cleaving saw is closed
#define SAW_CLOSED(saw) (!SAW_OPEN(saw))
/// Special attack modifier applied when doing a swiping attack to stop recursion
#define SWIPING_ATTACK "swipe_attack"
/// Special attack modifier applied when attacking nemesis factions
#define NEMESIS_ATTACK "nemesis"

/obj/item/melee/cleaving_saw
	name = "cleaving saw"
	desc = "This saw, effective at drawing the blood of beasts, transforms into a long cleaver that makes use of centrifugal force."
	icon = 'icons/obj/mining_zones/artefacts.dmi'
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	icon_state = "cleaving_saw"
	inhand_icon_state = "cleaving_saw"
	worn_icon_state = "cleaving_saw"
	attack_verb_continuous = list("attacks", "saws", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "saw", "slice", "tear", "lacerate", "rip", "dice", "cut")
	force = 12
	throwforce = 20
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	slot_flags = ITEM_SLOT_BELT
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	/// List of factions we deal bonus damage to
	var/list/nemesis_factions = list(FACTION_MINING, FACTION_BOSS)
	/// Amount of damage we deal to the above factions
	var/faction_bonus_force = 30
	/// Whether the cleaver is actively AoE swiping something.
	var/swiping = FALSE
	/// Amount of bleed stacks gained per hit
	var/bleed_stacks_per_hit = 3
	/// Force when the saw is opened.
	var/open_force = 20
	/// Throwforce when the saw is opened.
	var/open_throwforce = 20

/obj/item/melee/cleaving_saw/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		transform_cooldown_time = (CLICK_CD_MELEE * 0.25), \
		force_on = open_force, \
		throwforce_on = open_throwforce, \
		sharpness_on = sharpness, \
		hitsound_on = hitsound, \
		w_class_on = w_class, \
		attack_verb_continuous_on = list("cleaves", "swipes", "slashes", "chops"), \
		attack_verb_simple_on = list("cleave", "swipe", "slash", "chop"), \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/melee/cleaving_saw/examine(mob/user)
	. = ..()
	. += span_notice("It is [SAW_OPEN(src) ? "open, will cleave enemies in a wide arc and deal additional damage to fauna":"closed, and can be used for rapid consecutive attacks that cause fauna to bleed"].")
	. += span_notice("Both modes will build up existing bleed effects, doing a burst of high damage if the bleed is built up high enough.")
	. += span_notice("Transforming it immediately after an attack causes the next attack to come out faster.")

/obj/item/melee/cleaving_saw/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is [HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) ? "closing [src] on [user.p_their()] neck" : "opening [src] into [user.p_their()] chest"]! It looks like [user.p_theyre()] trying to commit suicide!"))
	attack_self(user)
	return BRUTELOSS

/obj/item/melee/cleaving_saw/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. || !isliving(target))
		return
	var/mob/living/smacking = target
	// closed = faster attacks
	if(SAW_CLOSED(src))
		SET_ATTACK_CLICK_CD(attack_modifiers, CLICK_CD_MELEE * 0.5)
	// open = more damage to mining mobs
	else if(faction_check(smacking.faction, nemesis_factions))
		MODIFY_ATTACK_FORCE(attack_modifiers, faction_bonus_force)
		LAZYSET(attack_modifiers, NEMESIS_ATTACK, TRUE)

/obj/item/melee/cleaving_saw/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	if(!isliving(target) || QDELETED(target))
		return
	if(SAW_CLOSED(src))
		afterattack_closed(target, user, attack_modifiers)
	else
		afterattack_open(target, user, attack_modifiers)

/obj/item/melee/cleaving_saw/proc/afterattack_closed(mob/living/target, mob/user, list/attack_modifiers)
	if(istype(target, /mob/living/simple_animal/hostile/asteroid/elite))
		return
	if(!LAZYACCESS(attack_modifiers, NEMESIS_ATTACK))
		return
	var/datum/status_effect/stacking/saw_bleed/existing_bleed = target.has_status_effect(/datum/status_effect/stacking/saw_bleed)
	if(existing_bleed)
		existing_bleed.add_stacks(bleed_stacks_per_hit)
	else
		target.apply_status_effect(/datum/status_effect/stacking/saw_bleed, bleed_stacks_per_hit)

/obj/item/melee/cleaving_saw/proc/afterattack_open(mob/living/target, mob/user, list/attack_modifiers)
	if(LAZYACCESS(attack_modifiers, SWIPING_ATTACK) || get_turf(target) == get_turf(user))
		return

	var/dir_to_target = get_dir(user, target)
	var/static/list/cleaving_saw_cleave_angles = list(0, -45, 45) //so that the animation animates towards the target clicked and not towards a side target
	for(var/i in cleaving_saw_cleave_angles)
		var/turf/turf = get_step(user, turn(dir_to_target, i))
		if(isnull(turf))
			continue

		for(var/mob/living/living_target in turf)
			if(living_target.body_position == LYING_DOWN)
				continue
			if(!living_target.IsReachableBy(user, reach))
				continue
			swipe_attack(living_target, user)

/// Basically a mini implementation of the main attack chain, future todo : refactor later
/obj/item/melee/cleaving_saw/proc/swipe_attack(mob/living/target, mob/living/user)
	var/list/attack_modifiers = list("[SWIPING_ATTACK]" = TRUE)

	if(pre_attack(target, user, null, attack_modifiers))
		target.attackby(src, user, null, attack_modifiers)

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Gives feedback and makes the nextmove after transforming much quicker.
 */
/obj/item/melee/cleaving_saw/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	user.changeNext_move(CLICK_CD_MELEE * 0.25)
	if(user)
		balloon_alert(user, "[active ? "opened" : "closed"] [src]")
	playsound(src, 'sound/effects/magic/clockwork/fellowship_armory.ogg', 35, TRUE, frequency = 90000 - (active * 30000))
	return COMPONENT_NO_DEFAULT_MESSAGE

#undef SAW_OPEN
#undef SAW_CLOSED
#undef SWIPING_ATTACK
#undef NEMESIS_ATTACK

// Wildhunter's butchering knife

/obj/item/knife/hunting/wildhunter
	name = "wildhunter's butchering knife"
	desc = "A magical knife made out of ashen stone. It was used to butcher local fauna by best hunters. Cuts everything to the simplest."
	icon = 'icons/obj/weapons/stabby_wide.dmi'
	inhand_icon_state = "wildhuntingknife"
	icon_state = "wildhuntingknife"
	icon_angle = 180
	force = 20
	wound_bonus = 15
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("slices", "hunts", "butchers", "pierces")
	attack_verb_simple = list("slice", "hunt", "butcher", "pierce")

//best butchering tool
/obj/item/knife/hunting/wildhunter/set_butchering()
	AddComponent(\
		/datum/component/butchering, \
		speed = 1.5 SECONDS , \
		effectiveness = 110, \
		bonus_modifier = 0, \
	)

/obj/item/knife/hunting/wildhunter/make_stabby()
	return

//cut those trophies
/obj/item/knife/hunting/wildhunter/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!istype(interacting_with, /obj/item/crusher_trophy))
		return NONE
	var/obj/item/crusher_trophy/trophy = interacting_with
	if(isnull(trophy.wildhunter_drop))
		return NONE
	balloon_alert(user, "cutting trophy...")
	if(!do_after(user, 4 SECONDS, trophy))
		return ITEM_INTERACT_BLOCKING
	new trophy.wildhunter_drop(trophy.drop_location())
	qdel(trophy)
	return ITEM_INTERACT_SUCCESS
