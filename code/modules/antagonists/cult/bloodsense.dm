/atom/movable/screen/alert/bloodsense
	name = "Blood Sense"
	desc = "Allows you to sense blood that is manipulated by dark magicks."
	icon_state = "cult_sense"
	alerttooltipstyle = "cult"
	/// Static image of a little nar'sie to show over the alert when the sacrifice is complete
	var/static/image/narnar
	/// The angle to the current target from the owner of the alert
	var/angle = 0
	/// Used for constructs, this points the arrow to either the construct's master or Nar'sie
	var/mob/living/simple_animal/hostile/construct/Cviewer = null

/atom/movable/screen/alert/bloodsense/Initialize(mapload)
	. = ..()
	if(!narnar)
		narnar = new('icons/hud/screen_alert.dmi', "mini_nar")
	START_PROCESSING(SSprocessing, src)

/atom/movable/screen/alert/bloodsense/Destroy()
	Cviewer = null
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/atom/movable/screen/alert/bloodsense/process()
	if(!owner.mind)
		// STOP_PROCESSING(SSprocessing, src)
		return

	// Who are we lookin' for
	var/atom/blood_target

	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(!cult_team)
		CRASH("Bloodsense on mob without a cult!")

	var/datum/objective/sacrifice/sac_objective = locate() in cult_team.objectives

	// We are a construct and we're looking for our master
	if(Cviewer && Cviewer.seeking && Cviewer.tracking_target?.resolve())
		blood_target = Cviewer.tracking_target.resolve()
		desc = "Your blood sense is leading you to [blood_target]." // melbert todo: never seen?

	// Cult has a set target and it's not in nullspace (???)
	else if(cult_team.blood_target && get_turf(cult_team.blood_target))
		blood_target = cult_team.blood_target

	if(isnull(blood_target))
		// No target and we need to sacrifice someone:
		// Track the sacrrifice target, but only in image, NOT via arrow
		if(sac_objective && !sac_objective.check_completion())
			if(icon_state == "runed_sense0") // Already set
				return

			animate(src, transform = null, time = 1, loop = 0)
			angle = 0
			cut_overlays()
			icon_state = "runed_sense0"
			desc = "Nar'Sie demands that [sac_objective.target] be sacrificed before the summoning ritual can begin."
			add_overlay(sac_objective.sac_image)
			return

		var/datum/objective/eldergod/summon_objective = locate() in cult_team.objectives
		if(!summon_objective)
			return

		var/list/location_list = list()
		for(var/area/area_to_check in summon_objective.summon_spots)
			location_list += area_to_check.get_original_area_name()
		desc = "The sacrifice is complete, summon Nar'Sie! The summoning can only take place in [english_list(location_list)]!"
		if(icon_state == "runed_sense1")
			return
		animate(src, transform = null, time = 1, loop = 0)
		angle = 0
		cut_overlays()
		icon_state = "runed_sense1"
		add_overlay(narnar)
		return

	var/turf/target_turf = get_turf(blood_target)
	var/turf/owner_turf = get_turf(owner)
	if(!target_turf || !owner_turf || !is_valid_z_level(owner_turf, target_turf))
		icon_state = "runed_sense2"
		desc = "You can no longer sense your target's presence."
		return
	if(isliving(blood_target))
		var/mob/living/real_target = blood_target
		desc = "You are currently tracking [real_target.real_name] in [get_area_name(blood_target)]."
	else
		desc = "You are currently tracking [blood_target] in [get_area_name(blood_target)]."
	if(target_turf.z != owner_turf.z) // multi-z map
		icon_state = "cult_sense"
		desc += " They are [target_turf.z > owner.z ? "above" : "below"] you!"
		return

	var/target_angle = get_angle(owner_turf, target_turf)
	var/target_dist = get_dist(target_turf, owner_turf)
	cut_overlays()
	switch(target_dist)
		if(0 to 1)
			icon_state = "runed_sense2"
		if(2 to 8)
			icon_state = "arrow8"
		if(9 to 15)
			icon_state = "arrow7"
		if(16 to 22)
			icon_state = "arrow6"
		if(23 to 29)
			icon_state = "arrow5"
		if(30 to 36)
			icon_state = "arrow4"
		if(37 to 43)
			icon_state = "arrow3"
		if(44 to 50)
			icon_state = "arrow2"
		if(51 to 57)
			icon_state = "arrow1"
		if(58 to 64)
			icon_state = "arrow0"
		if(65 to 400)
			icon_state = "arrow"

	var/difference = target_angle - angle
	angle = target_angle
	if(!difference)
		return
	var/matrix/final = matrix(transform)
	final.Turn(difference)
	animate(src, transform = final, time = 5, loop = 0)
