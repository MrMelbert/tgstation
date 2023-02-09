/datum/objective/sacrifice
	var/sacced = FALSE
	var/image/sac_image

/// Unregister signals from the old target so it doesn't cause issues when sacrificed of when a new target is found.
/datum/objective/sacrifice/proc/clear_sacrifice()
	if(!target)
		return
	UnregisterSignal(target, COMSIG_MIND_TRANSFERRED)
	if(target.current)
		UnregisterSignal(target.current, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_MIND_TRANSFERRED_INTO))
	target = null

/datum/objective/sacrifice/find_target(dupe_search_range, list/blacklist)
	if(!istype(team, /datum/team/cult))
		CRASH("Cult sacrifice objective without a cult team associated.")

	clear_sacrifice()
	var/datum/team/cult/cult = team
	var/list/desired_candidates = list()
	var/list/backup_candidates = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(!player.mind || IS_CULTIST(player) || player.stat == DEAD)
			continue
		if(is_convertable_to_cult(player))
			backup_candidates += player.mind
		else
			desired_candidates += player.mind

	if(!length(desired_candidates))
		if(!length(backup_candidates))
			message_admins("Cult setup: No sacrifice target could be found. WELP! The cult will be able to summon Nar'sie whenever.")
			sacced = TRUE // Prevents another hypothetical softlock. This basically means every PC is a cultist.
		else
			message_admins("Cult setup: A sacrifice target could not be found. Drawing from a broader pool of candidates.")
			target = pick(backup_candidates)
	else
		target = pick(desired_candidates)

	if(target)
		update_explanation_text()
		// Register a bunch of signals to both the target mind and its body
		// to stop cult from softlocking everytime the target is deleted before being actually sacrificed.
		RegisterSignal(target, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transfer))
		RegisterSignal(target.current, COMSIG_PARENT_QDELETING, PROC_REF(on_target_body_del))
		RegisterSignal(target.current, COMSIG_MOB_MIND_TRANSFERRED_INTO, PROC_REF(on_possible_mindswap))
		cult.make_image(src)

	for(var/datum/mind/mind as anything in cult.members)
		if(!isliving(mind.current))
			continue

		mind.current.clear_alert("bloodsense")
		mind.current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)

/// Target's body was QDELETED. Get a replacement for them
/datum/objective/sacrifice/proc/on_target_body_del()
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(find_target))

/// Target mindswapped. Point to the new body
/datum/objective/sacrifice/proc/on_mind_transfer(datum/source, mob/previous_body)
	SIGNAL_HANDLER

	//If, for some reason, the mind was transferred to a ghost (better safe than sorry), find a new target.
	if(!isliving(target.current))
		INVOKE_ASYNC(src, PROC_REF(find_target))
		return
	UnregisterSignal(previous_body, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_MIND_TRANSFERRED_INTO))
	RegisterSignal(target.current, COMSIG_PARENT_QDELETING, PROC_REF(on_target_body_del))
	RegisterSignal(target.current, COMSIG_MOB_MIND_TRANSFERRED_INTO, PROC_REF(on_possible_mindswap))

/// Target's body was mind swapped. Point to the new body
/datum/objective/sacrifice/proc/on_possible_mindswap(mob/source)
	SIGNAL_HANDLER

	UnregisterSignal(target.current, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_MIND_TRANSFERRED_INTO))
	//we check if the mind is bodyless only after mindswap shenanigeans to avoid issues.
	addtimer(CALLBACK(src, PROC_REF(do_we_have_a_body)), 1)

/datum/objective/sacrifice/proc/do_we_have_a_body()
	if(!target.current) //The player was ghosted and the mind isn't probably going to be transferred to another mob at this point.
		find_target()
		return
	RegisterSignal(target.current, COMSIG_PARENT_QDELETING, PROC_REF(on_target_body_del))
	RegisterSignal(target.current, COMSIG_MOB_MIND_TRANSFERRED_INTO, PROC_REF(on_possible_mindswap))

/datum/objective/sacrifice/check_completion()
	return sacced || completed

/datum/objective/sacrifice/update_explanation_text()
	if(target)
		explanation_text = "Sacrifice [target], the [target.assigned_role.title] via invoking an Offer rune with [target.p_them()] on it and three acolytes around it."
	else
		explanation_text = "The veil has already been weakened here, proceed to the final objective."
