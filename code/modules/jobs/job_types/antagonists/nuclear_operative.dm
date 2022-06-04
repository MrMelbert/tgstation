/datum/job/nuclear_operative
	title = ROLE_NUCLEAR_OPERATIVE
	outfit = /datum/outfit/syndicate
	plasmaman_outfit = /datum/outfit/syndicate/plasmaman

/datum/job/nuclear_operative/get_roundstart_spawn_point()
	return pick(GLOB.nukeop_start)

/datum/job/nuclear_operative/get_latejoin_spawn_point()
	return get_roundstart_spawn_point()

/datum/job/nuclear_operative/reinforcement
	outfit = /datum/outfit/syndicate/no_crystals
	plasmaman_outfit = /datum/outfit/syndicate/no_crystals/plasmaman

/datum/job/nuclear_operative/leader
	outfit = /datum/outfit/syndicate/leader
	plasmaman_outfit = /datum/outfit/syndicate/leader/plasmaman

/datum/job/nuclear_operative/clown
	title = ROLE_CLOWN_OPERATIVE
	outfit = /datum/outfit/syndicate/clownop
	plasmaman_outfit = /datum/outfit/syndicate/clownop/plasmaman

/datum/job/nuclear_operative/clown/reinforcement
	outfit = /datum/outfit/syndicate/clownop/no_crystals
	plasmaman_outfit = /datum/outfit/syndicate/clownop/no_crystals/plasmaman

/datum/job/nuclear_operative/clown/leader
	outfit = /datum/outfit/syndicate/clownop/leader
	plasmaman_outfit = /datum/outfit/syndicate/clownop/leader/plasmaman

/datum/job/nuclear_operative/lone
	title = ROLE_LONE_OPERATIVE
	outfit = /datum/outfit/syndicate/full

/datum/job/nuclear_operative/lone/get_roundstart_spawn_point()
	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/space_point in GLOB.landmarks_list)
		spawn_locs += space_point.loc

	return pick(spawn_locs)

/datum/job/nuclear_operative/lone/get_latejoin_spawn_point()
	return get_roundstart_spawn_point()
