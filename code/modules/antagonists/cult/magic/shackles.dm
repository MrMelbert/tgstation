/datum/action/cooldown/spell/touch/cult_shackles
	name = "Shadow Shackles"
	desc = "Will start handcuffing a victim on contact, and mute them if successful."
	DEFINE_CULT_ACTION("cuff", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "In'totum Lig'abis!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	hand_path = /obj/item/melee/touch_attack/cult/shackles

/datum/action/cooldown/spell/touch/cult_shackles/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell, charges = 4)

/datum/action/cooldown/spell/touch/cult_shackles/is_valid_target(atom/cast_on)
	var/mob/living/living_cast_on = cast_on
	return istype(living_cast_on) && !IS_CULTIST(living_cast_on)

/datum/action/cooldown/spell/touch/cult_shackles/proc/can_be_cuffed(mob/living/carbon/victim, mob/living/carbon/caster)
	if(!victim.canBeHandcuffed())
		victim.balloon_alert(caster, "can't be shackled!")
		return FALSE
	if(victim.handcuffed)
		victim.balloon_alert(caster, "already shackled!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/touch/cult_shackles/proc/cuff_checks(obj/item/melee/touch_attack/hand, mob/living/carbon/victim, mob/living/carbon/caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(victim) || QDELETED(hand))
		return FALSE
	if(!IsAvailable() || IS_CULTIST(victim))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/touch/cult_shackles/cast_on_hand_hit(obj/item/melee/touch_attack/hand, mob/living/carbon/victim, mob/living/carbon/caster)
	if(!can_be_cuffed(victim, caster))
		return FALSE

	playsound(caster, 'sound/weapons/cablecuff.ogg', 30, TRUE, -2)
	victim.visible_message(
		span_danger("[caster] begins restraining [victim] with dark magic!"),
		span_userdanger("[victim] begins shaping dark magic shackles around your wrists!"),
	)

	if(!do_after(caster, 3 SECONDS, victim, extra_checks = CALLBACK(src, PROC_REF(cuff_checks), hand, victim, caster)))
		victim.balloon_alert(user, "shackle failed!")
		return FALSE
	if(!can_be_cuffed(victim, caster))
		return FALSE

	victim.set_handcuffed(new /obj/item/restraints/handcuffs/energy/cult/used(victim))
	victim.update_handcuffed()
	victim.adjust_silence(10 SECONDS)
	victim.balloon_alert(caster, "shackled")
	// log_combat(caster, victim, "shadow shackled")
	return TRUE

/obj/item/melee/touch_attack/cult/shackles
	name = "shackling aura"
	desc = "Will start handcuffing a victim on contact, and mute them if successful."
	color = "#000000" // black

// The handcuffs applied by shadow shackles. They delete when taken off.
/obj/item/restraints/handcuffs/energy/cult
	name = "shadow shackles"
	desc = "Shackles that bind the wrists with sinister magic."
	trashtype = /obj/item/restraints/handcuffs/energy/used
	item_flags = DROPDEL

/obj/item/restraints/handcuffs/energy/cult/used/dropped(mob/user)
	user.visible_message(
		span_danger("[user]'s shackles shatter in a discharge of dark magic!"),
		span_userdanger("Your [src] shatters in a discharge of dark magic!"),
	)
	return ..()
