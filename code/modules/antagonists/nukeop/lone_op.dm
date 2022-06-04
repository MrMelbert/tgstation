/datum/antagonist/nukeop/lone
	name = "Lone Operative"
	// Lone ops are alone, duh. Always give them a new team.
	always_new_team = TRUE
	// Insertion into station space is handled via event.
	send_to_spawnpoint = FALSE
	nukeop_job = /datum/job/nuclear_operative/lone
	preview_outfit = /datum/outfit/nuclear_operative
	preview_outfit_behind = null
	nuke_icon_state = null

/datum/antagonist/nukeop/lone/assign_nuke()
	if(!nuke_team || nuke_team?.tracked_nuke)
		return

	nuke_team.memorized_code = random_nukecode()

	var/obj/machinery/nuclearbomb/selfdestruct/nuke = locate() in GLOB.nuke_list
	if(nuke)
		nuke_team.tracked_nuke = nuke
		if(nuke.r_code == "ADMIN")
			nuke.r_code = nuke_team.memorized_code
		else //Already set by admins/something else?
			nuke_team.memorized_code = nuke.r_code
	else
		stack_trace("Station self-destruct not found during lone op team creation.")
		nuke_team.memorized_code = null
