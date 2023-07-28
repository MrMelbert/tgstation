/obj/machinery/nuclearbomb/syndicate

/obj/machinery/nuclearbomb/syndicate/get_cinematic_type(detonation_status)
	switch(detonation_status)
		// The nuke detonated on station
		if(DETONATION_HIT_STATION)
			// And it was detonated by nuke ops
			if(length(get_antag_minds(/datum/antagonist/nukeop)))
				if(is_infiltrator_docked_at_syndiebase())
					// And the ops escaped, they won!
					return /datum/cinematic/nuke/ops_victory
				else
					// And the ops failed to escape, mutually assured destruction!
					return /datum/cinematic/nuke/mutual_destruction

			// It was detonated by something or someone what wasn't nuke ops,
			// throw it to the default explosion animation (self destruct)
			else
				return ..()

		// The nuke detonated on station Z, but in space
		if(DETONATION_NEAR_MISSED_STATION)
			return /datum/cinematic/nuke/ops_miss

		// The nuke detonated off station Z, and/or on the syndicate base
		if(DETONATION_HIT_SYNDIE_BASE, DETONATION_MISSED_STATION)
			return /datum/cinematic/nuke/far_explosion

	stack_trace("[type] - get_cinematic_type got a detonation_status it was not expecting. (Got: [detonation_status])")
	return /datum/cinematic/nuke/far_explosion

/obj/machinery/nuclearbomb/syndicate/arm_nuke(mob/armer)
	. = ..()
	if(IS_NUKE_OP(armer))
		armer.client?.give_award(/datum/award/achievement/antag/set_up_the_nuke, armer)

/obj/machinery/nuclearbomb/syndicate/disarm_nuke(mob/disarmer)
	. = ..()
	if(!IS_NUKE_OP(disarmer))
		disarmer.client?.give_award(/datum/award/achievement/misc/defused_nuke, disarmer)

/obj/machinery/nuclearbomb/syndicate/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()
	if(!timing && !exploding)
		return
	if(!pulledby || IS_NUKE_OP(pulledby))
		return
	if(!is_station_level(old_turf.z) || is_station_level(new_turf.z))
		return

	pulledby.client?.give_award(/datum/award/achievement/misc/spaced_nuke, pulledby)
