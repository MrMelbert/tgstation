/datum/action/cooldown/spell/touch/cult_teleport
	name = "Teleport"
	desc = "Will teleport a cultist to a teleport rune on contact."
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "tele"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	buttontooltipstyle = "cult"
	invocation = "Sas'so c'arta forbici!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE

	hand_path = /obj/item/melee/touch_attack/cult/teleport

/datum/action/cooldown/spell/touch/cult_teleport/New(Target, original)
	. = ..()
	AddComponent(/datum/component/blood_spell, charges = 1, health_cost = 7)

/datum/action/cooldown/spell/touch/cult_teleport/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return
	var/datum/antagonist/cultist = IS_CULTIST(owner)
	if(!cultist || !cultist.get_team())
		return FALSE

	return TRUE

/datum/action/cooldown/spell/touch/cult_teleport/is_valid_target(atom/cast_on)
	var/mob/living/living_cast_on = cast_on
	return istype(living_cast_on) && IS_CULTIST(living_cast_on)

/datum/action/cooldown/spell/touch/cult_teleport/cast_on_hand_hit(obj/item/melee/touch_attack/hand, mob/living/victim, mob/living/carbon/caster)
	var/datum/antagonist/cultist = caster.mind.has_antag_datum(/datum/antagonist/cult)
	var/datum/team/cult/cult_team = cultist.get_team()

	var/obj/effect/rune/teleport/actual_selected_rune = cult_team.select_teleport_rune(caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(victim) || QDELETED(hand) || QDELETED(actual_selected_rune))
		return FALSE
	if(!IsAvailable() || !caster.Adjacent(victim) || !IS_CULTIST(victim))
		return FALSE

	var/turf/start_turf = get_turf(victim)
	var/turf/dest = get_turf(actual_selected_rune)
	if(do_teleport(victim, dest, channel = TELEPORT_CHANNEL_CULT))
		start_turf.visible_message(
			span_warning("Dust flows from [caster]'s hand, and [caster == victim ? caster.p_they() : victim] disappear[victim.p_s()] with a sharp crack!"),
			blind_message = span_hear("You hear a sharp crack."),
			ignored_mobs = caster,
		)
		dest.visible_message(
			span_warning("There is a boom of outrushing air as something appears above [actual_selected_rune]!"),
			blind_message = span_hear("You hear a boom."),
			ignored_mobs = victim,
		)
		if(caster == victim)
			to_chat(caster, span_notice("You speak the words of the invocation, and find yourself somewhere else!"))
		else
			to_chat(caster, span_notice("You speak the words of the invocation, and send [victim] somewhere else!"))
			to_chat(victim, span_notice("You find yourself somewhere else!"))

	else
		start_turf.visible_message(span_warning("Dust flows from [caster]'s hand... but nothing appears to happen!"), ignored_mobs = caster)
		if(caster == victim)
			to_chat(caster, span_notice("You speak the words of the invocation... but you don't appear to have gone anywhere!"))
		else
			to_chat(caster, span_notice("You speak the words of the invocation... but [victim] is still here!"))

	return TRUE

/obj/item/melee/touch_attack/cult/teleport
	name = "teleporting aura"
	desc = "Will teleport a cultist to a teleport rune on contact."
	color = RUNE_COLOR_TELEPORT
