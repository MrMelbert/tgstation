/datum/action/cooldown/spell/aoe/veiling
	name = "Conceal Presence"
	desc = "Alternates between hiding and revealing nearby cult structures and runes."
	DEFINE_CULT_ACTION("gone", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "Kla'atu barada nikt'o!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	aoe_radius = 5
	var/revealing = FALSE

/datum/action/cooldown/spell/aoe/veiling/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell, charges = 10)

/datum/action/cooldown/spell/aoe/veiling/get_things_to_cast_on(atom/center)
	return RANGE_TURFS(aoe_radius, center)

/datum/action/cooldown/spell/aoe/veiling/update_button_name(atom/movable/screen/movable/action_button/button, force)
	. = ..()
	if(revealing)
		button.name = "Reveal Presence"
	else
		button.name = "Conceal Presence"

/datum/action/cooldown/spell/aoe/veiling/apply_button_icon(atom/movable/screen/movable/action_button/button, force)
	. = ..()
	if(revealing)
		button.icon_state = "back"
	else
		button.icon_state = "gone"

/datum/action/cooldown/spell/aoe/veiling/cast(atom/cast_on)
	if(revealing)
		owner.visible_message(
			span_warning("A flash of light shines from [owner]'s hand!"),
			span_cultitalic("You invoke the counterspell, revealing nearby runes."),
		)
		SEND_SOUND(owner, sound('sound/magic/enter_blood.ogg', 0, 1, 25))

	else
		cast_on.visible_message(
			span_warning("Thin grey dust falls from [cast_on]'s hand!"),
			span_cultitalic("You invoke the veiling spell, hiding nearby runes."),
		)
		SEND_SOUND(owner, sound('sound/magic/smoke.ogg', 0, 1, 25))

	. = ..()
	revealing = !revealing
	build_all_button_icons()

/datum/action/cooldown/spell/aoe/veiling/cast_on_thing_in_aoe(atom/victim, atom/caster)
	SEND_SIGNAL(victim, COMSIG_ATOM_CULT_VEILED, revealing, caster)
