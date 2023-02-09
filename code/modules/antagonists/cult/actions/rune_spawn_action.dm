//after a delay, creates a rune below you. for constructs creating runes.
/datum/action/cooldown/create_rune
	name = "Summon Rune"
	desc = "Summons a rune."
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	buttontooltipstyle = "cult"

	cooldown_time = 3 MINUTES

	// The rune that gets created when all's said and done
	var/obj/effect/rune/rune_type
	/// How long does it take to make the thing
	var/scribe_time = 6 SECONDS
	/// If TRUE, damage will interrupt the channel
	var/damage_interrupt = TRUE
	/// If TRUE, any action will interrup the channel
	var/action_interrupt = TRUE

	// These are used in animating the rune drawing
	var/obj/effect/temp_visual/cult/rune_spawn/rune_word_type
	var/obj/effect/temp_visual/cult/rune_spawn/rune_innerring_type
	var/obj/effect/temp_visual/cult/rune_spawn/rune_center_type
	var/rune_color

/datum/action/cooldown/create_rune/IsAvailable(feedback)
	return ..() && IS_CULTIST(owner)

/datum/action/cooldown/create_rune/proc/turf_check(turf/to_check)
	if(!to_check)
		return FALSE
	if(isspaceturf(to_check))
		to_check.balloon_alert(owner, "can't scribe in space!")
		return FALSE
	if(locate(/obj/effect/rune) in to_check)
		to_check.balloon_alert(owner, "already a rune here!")
		return FALSE
	if(!is_station_level(to_check.z) && !is_mining_level(to_check.z))
		to_check.balloon_alert(owner, "veil is not weak enough!")
		return FALSE
	return TRUE

/datum/action/cooldown/create_rune/Activate()
	StartCooldown(scribe_time)
	var/turf/below_us = get_turf(owner)
	if(!turf_check(below_us))
		return FALSE

	var/chosen_keyword
	if(initial(rune_type.req_keyword))
		chosen_keyword = tgui_input_text(owner, "Enter a keyword for the new rune.", "Words of Power", max_length = MAX_NAME_LEN)
		if(!chosen_keyword || QDELETED(src) || QDELETED(owner))
			return FALSE
		below_us = get_turf(owner)
		if(!turf_check(below_us))
			return FALSE

	//the outer ring is always the same across all runes
	var/obj/effect/temp_visual/cult/rune_spawn/R1 = new(below_us, scribe_time, rune_color)
	//the rest are not always the same, so we need types for em
	var/obj/effect/temp_visual/cult/rune_spawn/R2
	if(ispath(rune_word_type, /obj/effect/temp_visual/cult/rune_spawn))
		R2 = new rune_word_type(below_us, scribe_time, rune_color)
	var/obj/effect/temp_visual/cult/rune_spawn/R3
	if(ispath(rune_innerring_type, /obj/effect/temp_visual/cult/rune_spawn))
		R3 = new rune_innerring_type(below_us, scribe_time, rune_color)
	var/obj/effect/temp_visual/cult/rune_spawn/R4
	if(ispath(rune_center_type, /obj/effect/temp_visual/cult/rune_spawn))
		R4 = new rune_center_type(below_us, scribe_time, rune_color)

	var/list/health
	if(damage_interrupt && isliving(owner))
		var/mob/living/living_owner = owner
		health = list("health" = living_owner.health)
	var/scribe_mod = scribe_time
	if(istype(below_us, /turf/open/floor/engine/cult))
		scribe_mod *= 0.5

	playsound(below_us, 'sound/magic/enter_blood.ogg', 100, FALSE)
	if(do_after(owner, scribe_mod, target = below_us, extra_checks = CALLBACK(owner, TYPE_PROC_REF(/mob, break_do_after_checks), health, action_interrupt)))
		new rune_type(owner.loc, chosen_keyword)
		StartCooldown()
		return TRUE

	qdel(R1)
	qdel(R2)
	qdel(R3)
	qdel(R4)
	StartCooldown(cooldown_time / 3)
	return FALSE

//teleport rune
/datum/action/cooldown/create_rune/tele
	name = "Summon Teleport Rune"
	desc = "Summons a teleport rune to your location, as though it has been there all along..."
	button_icon_state = "telerune"
	rune_type = /obj/effect/rune/teleport
	rune_word_type = /obj/effect/temp_visual/cult/rune_spawn/rune2
	rune_innerring_type = /obj/effect/temp_visual/cult/rune_spawn/rune2/inner
	rune_center_type = /obj/effect/temp_visual/cult/rune_spawn/rune2/center
	rune_color = RUNE_COLOR_TELEPORT

/datum/action/cooldown/create_rune/wall
	name = "Summon Barrier Rune"
	desc = "Summons an active barrier rune to your location, as though it has been there all along..."
	button_icon_state = "barrier"
	rune_type = /obj/effect/rune/wall
	rune_word_type = /obj/effect/temp_visual/cult/rune_spawn/rune4
	rune_innerring_type = /obj/effect/temp_visual/cult/rune_spawn/rune4/inner
	rune_center_type = /obj/effect/temp_visual/cult/rune_spawn/rune4/center
	rune_color = RUNE_COLOR_DARKRED

/datum/action/cooldown/create_rune/revive
	name = "Summon Revive Rune"
	desc = "Summons a revive rune to your location, as though it has been there all along..."
	button_icon_state = "revive"
	rune_type = /obj/effect/rune/raise_dead
	rune_word_type = /obj/effect/temp_visual/cult/rune_spawn/rune1
	rune_innerring_type = /obj/effect/temp_visual/cult/rune_spawn/rune1/inner
	rune_center_type = /obj/effect/temp_visual/cult/rune_spawn/rune1/center
	rune_color = RUNE_COLOR_MEDIUMRED
