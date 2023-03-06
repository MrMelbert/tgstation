/datum/action/cooldown/spell/pointed/cultmark
	name = "Mark Target"
	desc = "Marks a target for the cult."
	DEFINE_CULT_ACTION("cult_mark", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	cooldown_time = 2 MINUTES
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	active_msg = span_cult("You prepare to mark a target for your cult. <b>Click a target to mark them!</b>")
	deactive_msg = span_cult("You cease the marking ritual.")
	cast_range = 7

	/// The duration of the mark itself
	var/cult_mark_duration = 90 SECONDS

/datum/action/cooldown/spell/pointed/cultmark/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	if(GLOB.cult_narsie)
		return FALSE
	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(!cult_team || cult_team.blood_target)
		return FALSE

	return TRUE

/datum/action/cooldown/spell/pointed/cultmark/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on) && (get_turf(cast_on) in view(get_turf(owner)))

/datum/action/cooldown/spell/pointed/cultmark/cast(mob/living/cast_on)
	. = ..()

	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(!cult_team.set_blood_target(cast_on, owner, cult_mark_duration))
		to_chat(owner, span_cult("The marking rite failed!"))
		return

	to_chat(owner, span_cult("The marking rite is complete! It will last for [DisplayTimeText(cult_mark_duration)] seconds."))

/datum/action/cooldown/spell/ghostmark //Ghost version
	name = "Blood Mark your Target"
	desc = "LMB: Marks whatever you are orbiting for the entire cult to track. | \
		RMB: Clears the cult's current blood mark (works while on cooldown)."
	DEFINE_CULT_ACTION("cult_mark", 'icons/mob/actions/actions_cult.dmi')
	check_flags = NONE

	cooldown_time = 60 SECONDS

	/// The duration of the mark on the target
	var/cult_mark_duration = 60 SECONDS
	/// Tracks whether we were r-clicked or l-clicked on our last trigger
	var/right_clicked = FALSE

/datum/action/cooldown/spell/ghostmark/Trigger(trigger_flags, atom/target)
	if(trigger_flags & TRIGGER_SECONDARY_ACTION) // Replace this with better right click spell action API later
		right_clicked = TRUE
	return ..()

/datum/action/cooldown/spell/ghostmark/can_cast_spell(feedback)
	return ..() && isobserver(owner) && GET_CULT_TEAM(owner)

/datum/action/cooldown/spell/ghostmark/is_valid_target(atom/cast_on)
	return isobserver(cast_on)

/datum/action/cooldown/spell/ghostmark/PreActivate(atom/target)
	if(!right_clicked)
		return ..()

	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(cult_team?.blood_target)
		cult_team.unset_blood_target_and_timer()
		to_chat(owner, span_cultbold("You have cleared the cult's blood target!"))
	right_clicked = FALSE

/datum/action/cooldown/spell/ghostmark/cast(atom/cast_on)
	. = ..()
	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	var/atom/mark_target = owner.orbiting?.parent || get_turf(owner)
	if(isnull(mark_target))
		return

	if(!cult_team.set_blood_target(mark_target, owner, cult_mark_duration))
		to_chat(owner, span_cult("The marking failed!"))
		return

	to_chat(owner, span_cultbold("You have marked [mark_target] for the cult! It will last for [DisplayTimeText(cult_mark_duration)]."))
