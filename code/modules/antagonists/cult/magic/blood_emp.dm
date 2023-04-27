/datum/action/cooldown/spell/emp/cult
	name = "Electromagnetic Pulse"
	desc = "Emits a large electromagnetic pulse."
	DEFINE_CULT_ACTION("emp", 'icons/mob/actions/actions_spells.dmi')

	sound = 'sound/effects/empulse.ogg'
	invocation = "Ta'gh fara'qha fel d'amar det!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE

	emp_heavy = 2
	emp_light = 5

/datum/action/cooldown/spell/emp/cult/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell/blood_cost, charges = 1, health_cost = 10)

/datum/action/cooldown/spell/emp/cult/cast(atom/cast_on)
	cast_on.visible_message(
		span_warning("[cast_on]'s hand flashes a bright blue!"),
		span_cultitalic("You speak the cursed words, emitting an EMP blast from your hand."),
	)
	return ..()
