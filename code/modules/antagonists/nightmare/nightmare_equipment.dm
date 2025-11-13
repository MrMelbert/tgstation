/**
 * An armblade that instantly snuffs out lights
 */
/obj/item/light_eater
	name = "light eater" //as opposed to heavy eater
	icon = 'icons/obj/weapons/changeling_items.dmi'
	icon_state = "arm_blade"
	inhand_icon_state = "arm_blade"
	icon_angle = 180
	force = 25
	armour_penetration = 35
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	item_flags = ABSTRACT | DROPDEL
	resistance_flags = INDESTRUCTIBLE | ACID_PROOF | FIRE_PROOF | LAVA_PROOF | UNACIDABLE
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	tool_behaviour = TOOL_MINING
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	wound_bonus = -30
	exposed_wound_bonus = 20
	///If this is true, our next hit will be critcal, temporarily stunning our target
	var/has_crit = FALSE
	///The timer which controls our next crit
	var/crit_timer

/obj/item/light_eater/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)
	AddComponent(/datum/component/butchering, \
	speed = 8 SECONDS, \
	effectiveness = 70, \
	)
	AddComponent(/datum/component/light_eater)

/obj/item/light_eater/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!user?.mind?.has_antag_datum(/datum/antagonist/nightmare))
		return
	RegisterSignal(user, COMSIG_MOB_ENTER_JAUNT, PROC_REF(prepare_crit_timer))
	RegisterSignal(user, COMSIG_MOB_AFTER_EXIT_JAUNT, PROC_REF(stop_crit_timer))

/obj/item/light_eater/dropped(mob/user, silent = FALSE)
	. = ..()
	if(!user?.mind?.has_antag_datum(/datum/antagonist/nightmare))
		return
	UnregisterSignal(user, COMSIG_MOB_ENTER_JAUNT)
	UnregisterSignal(user, COMSIG_MOB_AFTER_EXIT_JAUNT)
	remove_crit()

#define CRIT_ATTACK "critical_strike"
/// No stun but double damage
#define DAMAGE_CRIT 1
/// Full stun
#define STUN_CRIT 2

/obj/item/light_eater/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. || !has_crit || !isliving(target))
		return

	var/mob/living/attacking = target
	HIDE_ATTACK_MESSAGES(attack_modifiers)
	if(attacking.check_stun_immunity(CANSTUN))
		LAZYSET(attack_modifiers, CRIT_ATTACK, DAMAGE_CRIT)
		MODIFY_ATTACK_FORCE_MULTIPLIER(attack_modifiers, 2)
	else
		LAZYSET(attack_modifiers, CRIT_ATTACK, STUN_CRIT)

/obj/item/light_eater/afterattack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!isliving(target) || !LAZYACCESS(attack_modifiers, CRIT_ATTACK))
		return

	var/mob/living/attacking = target
	playsound(attacking, 'sound/effects/wounds/crackandbleed.ogg', 100, TRUE)
	if(attacking.stat == DEAD)
		user.visible_message(
			span_warning("[user] gores [attacking] with [src]!"),
			span_warning("You gore [attacking] with [src], which doesn't accomplish much, but it does make you feel a little better."),
		)
	else if(LAZYACCESS(attack_modifiers, CRIT_ATTACK) == STUN_CRIT)
		user.visible_message(
			span_boldwarning("[user] gores [attacking] with [src], bringing them to a halt!"),
			span_userdanger("You gore [attacking] with [src], bringing them to a halt!"),
		)
		attacking.Paralyze(issilicon(attacking) ? 2 SECONDS : 1 SECONDS)
	else
		user.visible_message(
			span_boldwarning("[user] gores [attacking] with [src], ripping into them!"),
			span_userdanger("You gore [attacking] with [src], ripping into them!"),
		)
	remove_crit()

#undef CRIT_ATTACK
#undef DAMAGE_CRIT
#undef STUN_CRIT

/obj/item/light_eater/proc/prepare_crit_timer()
	crit_timer = addtimer(CALLBACK(src, PROC_REF(add_crit)), 7 SECONDS, TIMER_DELETE_ME | TIMER_STOPPABLE)

/obj/item/light_eater/proc/stop_crit_timer()
	deltimer(crit_timer)

/obj/item/light_eater/proc/add_crit()
	if(has_crit)
		return
	has_crit = TRUE
	add_filter("crit_glow", 3, list("type" = "outline", "color" = COLOR_CARP_RIFT_RED, "size" = 5))
	if(ismob(loc))
		loc.balloon_alert(loc, "critical strike ready")

/obj/item/light_eater/proc/remove_crit()
	if(!has_crit)
		return
	has_crit = FALSE
	remove_filter("crit_glow")
	stop_crit_timer()
