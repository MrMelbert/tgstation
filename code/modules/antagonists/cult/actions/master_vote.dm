/datum/action/cult_master_vote
	name = "Assert Leadership"
	DEFINE_CULT_ACTION("cultvote", 'icons/mob/actions/actions_cult.dmi')

	/// Votes cannot be polled before this world time
	var/min_allowed_world_time = 240 SECONDS

/datum/action/cult_master_vote/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(!cult_team || cult_team.cult_vote_called)
		return FALSE
	if(world.time < min_allowed_world_time)
		if(feedback)
			to_chat(owner, "It would be premature to select a leader while everyone is still settling in, \
				try again in [DisplayTimeText(min_allowed_world_time - world.time)].")
		return FALSE
	return TRUE

/datum/action/cult_master_vote/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	var/choice = tgui_alert(owner, "The mantle of leadership is heavy. Success in this role requires an expert level of communication and experience. Are you sure?",, list("Yes", "No"))
	if(choice != "Yes" || QDELETED(src) || QDELETED(owner) || !IsAvailable())
		return

	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	cult_team.poll_cultists(owner)

/// Cult Master poll
/datum/team/cult/proc/poll_cultists(mob/living/nominee)
	cult_vote_called = TRUE //somebody's trying to be a master, make sure we don't let anyone else try
	for(var/datum/mind/team_cultist as anything in members)
		if(team_cultist.current?.incapacitated())
			continue

		team_cultist.current.update_mob_action_buttons()
		to_chat(team_cultist.current, span_cultlarge("Acolyte [nominee.real_name] has asserted that [nominee.p_theyre()] worthy of leading the cult. \
			A vote will be called shortly."))

	var/nominee_name_in_case_of_delete = nominee.real_name
	sleep(10 SECONDS)
	if(QDELETED(nominee) || nominee.stat == DEAD || nominee.incapacitated() || !nominee.mind || !IS_CULTIST(nominee))
		cult_vote_called = FALSE
		for(var/datum/mind/team_cultist as anything in members)
			if(team_cultist.current?.incapacitated())
				continue

			team_cultist.current.update_mob_action_buttons()
			to_chat(team_cultist.current, span_cultlarge("Acolyte [nominee_name_in_case_of_delete] is no longer in a valid state to lead, and the vote has reset."))
		return

	var/list/asked_cultists = list()
	for(var/datum/mind/team_cultist as anything in members)
		if(team_cultist.current?.incapacitated())
			continue
		SEND_SOUND(team_cultist.current, 'sound/magic/exit_blood.ogg')
		asked_cultists += team_cultist.current

	var/list/yes_voters = poll_candidates("[nominee.real_name] seeks to lead your cult, do you support [nominee.p_them()]?", poll_time = 30 SECONDS, group = asked_cultists)
	if(QDELETED(nominee) || nominee.stat == DEAD || nominee.incapacitated() || !nominee.mind || !IS_CULTIST(nominee))
		cult_vote_called = FALSE
		for(var/datum/mind/team_cultist as anything in members)
			if(team_cultist.current?.incapacitated())
				continue

			team_cultist.current.update_mob_action_buttons()
			to_chat(team_cultist.current, span_cultlarge("Acolyte [nominee_name_in_case_of_delete] is no longer in a valid state to lead, and the vote has reset."))
		return

	if(LAZYLEN(yes_voters) <= LAZYLEN(asked_cultists) * 0.5)
		cult_vote_called = FALSE
		for(var/datum/mind/team_cultist as anything in members)
			if(team_cultist.current?.incapacitated())
				continue

			team_cultist.current.update_mob_action_buttons()
			to_chat(team_cultist.current, span_cultlarge("[nominee.real_name] could not win the cult's support and shall continue to serve as an acolyte."))
		return FALSE

	// -- Master elected --
	cult_master = nominee
	var/datum/antagonist/cult/old_datum = nominee.mind.has_antag_datum(/datum/antagonist/cult)
	var/datum/cult_magic_holder/old_holder
	if (old_datum)
		// grab their holder so it doesn't get deleted
		old_holder = old_datum.magic_holder
		old_datum.magic_holder = null
		// remove their old datum silently
		old_datum.silent = TRUE
		old_datum.on_removal()

	var/datum/antagonist/cult/master/new_datum = nominee.mind.add_antag_datum(/datum/antagonist/cult/master)
	if(old_holder)
		// get rid of that new lame one
		QDEL_NULL(new_datum.magic_holder)
		// pass in our old one and give them all their old spells back
		new_datum.magic_holder = old_holder
		// old_holder.give_to_cultist(Nominee) // melbert todo, not necessary?

	// -- Alert thec ult of their new master --
	for(var/datum/mind/team_cultist as anything in members)
		var/datum/antagonist/cult/team_cultist_datum = team_cultist.has_antag_datum(/datum/antagonist/cult)
		QDEL_NULL(team_cultist_datum.vote)
		if(team_cultist.current.incapacitated())
			continue

		to_chat(team_cultist.current, span_cultlarge("[nominee] has won the cult's support and is now their master. \
			Follow [nominee.p_their()] orders to the best of your ability!"))

	return TRUE
