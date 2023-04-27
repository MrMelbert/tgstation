/datum/action/cooldown/spell/pointed/horrors
	name = "Hallucinations"
	desc = "Gives hallucinations to a target at range. A silent and invisible spell."
	DEFINE_CULT_ACTION("horror", 'icons/mob/actions/actions_cult.dmi')
	ranged_mousepointer = 'icons/effects/mouse_pointers/cult_target.dmi'

	sound = null
	invocation_type = INVOCATION_NONE
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	active_msg = span_cult("You prepare to horrify a target...")
	deactive_msg = span_cult("You dispel the magic...")

/datum/action/cooldown/spell/pointed/horrors/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell, charges = 4)

/datum/action/cooldown/spell/pointed/horrors/is_valid_target(atom/cast_on)
	var/mob/living/living_cast_on = cast_on
	return istype(living_cast_on) && !IS_CULTIST(living_cast_on)

/datum/action/cooldown/spell/pointed/horrors/cast(mob/living/cast_on)
	. = ..()

	cast_on.set_hallucinations_if_lower(240 SECONDS)

	var/image/sparkle_image = image('icons/effects/cult/effects.dmi', cast_on, "bloodsparkles", ABOVE_MOB_LAYER)
	cast_on.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/cult, "cult_apoc", sparkle_image, NONE)
	addtimer(CALLBACK(cast_on, TYPE_PROC_REF(/atom, remove_alt_appearance), "cult_apoc", TRUE), 4 MINUTES, TIMER_OVERRIDE|TIMER_UNIQUE)

	SEND_SOUND(owner, sound('sound/effects/ghost.ogg', FALSE, TRUE, 50))
	to_chat(owner, span_cultbold("[cast_on] has been cursed with living nightmares!"))
