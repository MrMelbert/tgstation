#define CULT_VICTORY 1
#define CULT_LOSS 0
#define CULT_NARSIE_KILLED -1

/datum/antagonist/cult
	name = "Cultist"
	roundend_category = "cultists"
	antagpanel_category = "Cult"
	antag_moodlet = /datum/mood_event/cult
	suicide_cry = "FOR NAR'SIE!!"
	preview_outfit = /datum/outfit/cultist
	job_rank = ROLE_CULTIST
	antag_hud_name = "cult"

	/// Our team of cultists.
	/// Use [proc/get_team()] to access it.
	VAR_PROTECTED/datum/team/cult/cult_team

	/// Action that allows for our cultists to communicate with one another
	var/datum/action/cooldown/spell/cult_commune/communion
	/// Action that allows for a cult to pronounce themselves as leader
	var/datum/action/cult_master_vote/vote

	/// If TRUE, mindshielded people can gain this cult datum
	var/ignore_implant = FALSE
	/// If TRUE, the cultist will be given a dagger and runed metal when they gain the datum.
	var/give_equipment = FALSE
	/// A reference to the cult magic datum that allows our cultist to cast and prepare spells.
	var/datum/cult_magic_holder/magic_holder

/datum/antagonist/cult/get_team()
	return cult_team

/datum/antagonist/cult/create_team(datum/team/cult/new_team)
	if(!new_team)
		//todo remove this and allow admin buttons to create more than one cult // melbert eyes
		for(var/datum/antagonist/cult/other_cultist in GLOB.antagonists)
			if(!other_cultist.owner)
				continue
			if(other_cultist.cult_team)
				cult_team = other_cultist.cult_team
				return
		cult_team = new()
		cult_team.setup_objectives()
		return

	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	cult_team = new_team

/datum/antagonist/cult/proc/add_objectives()
	objectives |= cult_team.objectives

/datum/antagonist/cult/Destroy()
	QDEL_NULL(communion)
	QDEL_NULL(vote)
	return ..()

/datum/antagonist/cult/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(. && !ignore_implant)
		. = is_convertable_to_cult(new_owner.current,cult_team)

/datum/antagonist/cult/greet()
	. = ..()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/bloodcult.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)//subject to change
	owner.announce_objectives()

/datum/antagonist/cult/on_gain()
	add_objectives()

	// Some relevant actions (granted in innate effecst)
	if(!cult_team.cult_master)
		vote = new(src)
	communion = new(src)

	// Create the magic holder datum
	magic_holder = new()

	. = ..()

	var/mob/living/current = owner.current
	if(give_equipment)
		equip_cultist(TRUE)
	current.log_message("has been converted to the cult of Nar'Sie!", LOG_ATTACK, color="#960000")

	if(cult_team.blood_target && cult_team.blood_target_image && current.client)
		current.client.images += cult_team.blood_target_image

/datum/antagonist/cult/on_removal()
	if(!silent)
		owner.current.visible_message(span_deconversion_message("[owner.current] looks like [owner.current.p_theyve()] just reverted to [owner.current.p_their()] old faith!"), ignored_mobs = owner.current)
		to_chat(owner.current, span_userdanger("An unfamiliar white light flashes through your mind, cleansing the taint of the Geometer and all your memories as her servant."))
		owner.current.log_message("has renounced the cult of Nar'Sie!", LOG_ATTACK, color="#960000")
	if(cult_team.blood_target && cult_team.blood_target_image && owner.current.client)
		owner.current.client.images -= cult_team.blood_target_image

	QDEL_NULL(magic_holder)
	return ..()

/datum/antagonist/cult/get_preview_icon()
	var/icon/icon = render_preview_outfit(preview_outfit)

	// The longsword is 64x64, but getFlatIcon crunches to 32x32.
	// So I'm just going to add it in post, screw it.

	// Center the dude, because item icon states start from the center.
	// This makes the image 64x64.
	icon.Crop(-15, -15, 48, 48)

	var/obj/item/melee/cultblade/longsword = new
	icon.Blend(icon(longsword.lefthand_file, longsword.inhand_icon_state), ICON_OVERLAY)
	qdel(longsword)

	// Move the guy back to the bottom left, 32x32.
	icon.Crop(17, 17, 48, 48)

	return finish_preview_icon(icon)

/datum/antagonist/cult/proc/equip_cultist(metal=TRUE)
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	. += cult_give_item(/obj/item/melee/cultblade/dagger, H)
	if(metal)
		. += cult_give_item(/obj/item/stack/sheet/runed_metal/ten, H)
	to_chat(owner, "These will help you start the cult on this station. Use them well, and remember - you are not the only one.</span>")


/datum/antagonist/cult/proc/cult_give_item(obj/item/item_path, mob/living/carbon/human/mob)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
	)

	var/T = new item_path(mob)
	var/item_name = initial(item_path.name)
	var/where = mob.equip_in_one_of_slots(T, slots)
	if(!where)
		to_chat(mob, span_userdanger("Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1)."))
		return FALSE
	else
		to_chat(mob, span_danger("You have a [item_name] in your [where]."))
		if(where == "backpack")
			mob.back.atom_storage?.show_contents(mob)
		return TRUE

/datum/antagonist/cult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current

	handle_clown_mutation(current, mob_override ? null : "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	current.faction |= FACTION_CULT
	current.grant_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST)

	vote?.Grant(current) // vote is null if a master exists
	communion.Grant(current)
	magic_holder.give_to_cultist(current)

	current.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(cult_team.cult_risen)
		current.AddElement(/datum/element/cult_eyes, initial_delay = 0 SECONDS)
	if(cult_team.cult_ascendent)
		current.AddElement(/datum/element/cult_halo, initial_delay = 0 SECONDS)
	ADD_TRAIT(current, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)

	add_team_hud(current)

/datum/antagonist/cult/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current

	handle_clown_mutation(current, removing = FALSE)
	current.faction -= FACTION_CULT
	current.remove_language(/datum/language/narsie, TRUE, TRUE, LANGUAGE_CULTIST)
	vote?.Remove(current)
	communion.Remove(current)
	current.clear_alert("bloodsense")

	if (cult_team.cult_risen)
		current.RemoveElement(/datum/element/cult_eyes)
	if (cult_team.cult_ascendent)
		current.RemoveElement(/datum/element/cult_halo)

	REMOVE_TRAIT(current, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)

/datum/antagonist/cult/on_mindshield(mob/implanter)
	if(!silent)
		to_chat(owner.current, span_warning("You feel something interfering with your mental conditioning, but you resist it!"))
	return

/datum/antagonist/cult/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = FALSE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has cult-ed [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has cult-ed [key_name(new_owner)].")

/datum/antagonist/cult/admin_remove(mob/user)
	silent = TRUE
	return ..()

/datum/antagonist/cult/get_admin_commands()
	. = ..()
	.["Dagger"] = CALLBACK(src, PROC_REF(admin_give_dagger))
	.["Dagger and Metal"] = CALLBACK(src, PROC_REF(admin_give_metal))
	.["Remove Dagger and Metal"] = CALLBACK(src, PROC_REF(admin_take_all))

/datum/antagonist/cult/proc/admin_give_dagger(mob/admin)
	if(!equip_cultist(metal = FALSE))
		to_chat(admin, span_danger("Spawning dagger failed!"))

/datum/antagonist/cult/proc/admin_give_metal(mob/admin)
	if (!equip_cultist(metal = TRUE))
		to_chat(admin, span_danger("Spawning runed metal failed!"))

/datum/antagonist/cult/proc/admin_take_all(mob/admin)
	var/mob/living/current = owner.current
	for(var/o in current.get_all_contents())
		if(istype(o, /obj/item/melee/cultblade/dagger) || istype(o, /obj/item/stack/sheet/runed_metal))
			qdel(o)

/datum/antagonist/cult/master
	ignore_implant = TRUE
	show_in_antagpanel = FALSE //Feel free to add this later
	antag_hud_name = "cultmaster"

	// THREE NEWS SPELLS FOR OUR FRIEND THE MASTER
	var/datum/action/cooldown/spell/final_reckoning/reckoning
	var/datum/action/cooldown/spell/pointed/cultmark/bloodmark
	var/datum/action/cooldown/spell/pointed/pulse/throwing

/datum/antagonist/cult/master/on_gain()
	reckoning = new(src)
	bloodmark = new(src)
	throwing = new(src)
	return ..()

/datum/antagonist/cult/master/Destroy()
	QDEL_NULL(reckoning)
	QDEL_NULL(bloodmark)
	QDEL_NULL(throwing)
	return ..()

/datum/antagonist/cult/master/greet()
	to_chat(owner.current, "<span class='warningplain'>\
		<span class='cultlarge'>You are the cult's Master</span>. \
		As the cult's Master, you have a unique title and loud voice when communicating, are capable of marking targets, \
		such as a location or a noncultist, to direct the cult to them, and, finally, you are capable of summoning \
		the entire living cult to your location <b><i>once</i></b>. \
		Use these abilities to direct the cult to victory at any cost.</span>")

/datum/antagonist/cult/master/on_removal()
	. = ..()
	if(!silent && isliving(owner.current))
		var/mob/living/former_owner = owner.current
		// Announce deconversion a good bit after it happens
		addtimer(CALLBACK(src, PROC_REF(announce_loss), former_owner.real_name, "was deconverted from our cult", get_area(former_owner)), 12 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/antagonist/cult/master/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current

	reckoning.Grant(current)
	bloodmark.Grant(current)
	throwing.Grant(current)

	add_team_hud(current, /datum/antagonist/cult)
	RegisterSignal(current, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/antagonist/cult/master/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current

	reckoning.Remove(current)
	bloodmark.Remove(current)
	throwing.Remove(current)

	UnregisterSignal(current, COMSIG_LIVING_DEATH)

/**
 * Announces to the whole cult if the leader was killed / gibbed, or deconverted
 *
 * * former_leader - Text name of the leader who has fallen
 * * message - the message displayed to everyone
 * * location - where the deed happened
 */
/datum/antagonist/cult/master/proc/announce_loss(former_leader, message = "has fallen", area/location)
	if(!QDELETED(GLOB.cult_narsie)) // Nar'sie is here, don't care
		return
	if(isliving(owner.current) && owner.current.stat != DEAD) // I'm not dead yet!
		return

	for(var/datum/mind/cultist as anything in cult_team.members)
		if(!isliving(cultist.current))
			continue

		var/mob/living/living_cultist = cultist.current
		SEND_SOUND(living_cultist, sound('sound/hallucinations/veryfar_noise.ogg'))
		to_chat(living_cultist, span_cultlarge("The cult's Master, [former_leader], [message] in \the [location]!"))

/datum/antagonist/cult/master/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER

	// Announce death shortly after falling
	// This is a short timer to prevent death -> revival -> death spam
	addtimer(CALLBACK(src, PROC_REF(announce_loss), source.real_name, "has fallen", get_area(source)), 4 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/team/cult
	name = "\improper Cult"

	///The blood mark target
	var/atom/blood_target
	///Image of the blood mark target
	var/image/blood_target_image
	///Timer for the blood mark expiration
	var/blood_target_reset_timer

	///Has a vote been called for a leader?
	var/cult_vote_called = FALSE
	///The cult leader
	var/mob/living/cult_master
	///Has the mass teleport been used yet?
	var/reckoning_complete = FALSE
	///Has the cult risen, and gotten red eyes?
	var/cult_risen = FALSE
	///Has the cult asceneded, and gotten halos?
	var/cult_ascendent = FALSE

	///Has narsie been summoned yet?
	var/narsie_summoned = FALSE
	///How large were we at max size.
	var/size_at_maximum = 0
	///list of cultists just before summoning Narsie
	var/list/true_cultists = list()

	/// List of teleport runes associated with this cult
	var/list/obj/effect/rune/teleport/teleport_runes = list()

	/// The number of ritual sites this cult will have to summon nar'sie
	var/max_ritual_sites = 3
	/// A list of references to station areas that we can summon nar'sie in
	var/list/area/station/ritual_sites = list()

/datum/team/cult/New(starting_members)
	. = ..()
	var/sanity = 0
	while(ritual_sites.len < max_ritual_sites && sanity < 100)
		var/area/summon_area = pick(GLOB.areas - ritual_sites)
		if(summon_area && is_station_level(summon_area.z) && (summon_area.area_flags & VALID_TERRITORY))
			ritual_sites += summon_area
		sanity++

/datum/team/cult/Destroy() // shouldn't ever happen but whateva
	ritual_sites.Cut()
	teleport_runes.Cut()
	cult_master = null
	unset_blood_target()
	return ..()

/datum/team/cult/proc/check_size()
	if(cult_ascendent) // From here on size doesn't matter (heh)
		return

#ifdef UNIT_TESTS
	// This proc is unnecessary clutter whilst running cult related unit tests
	// Remove this if, at some point, someone decides to test that halos and eyes are added at expected ratios
	return
#endif

	var/alive = 0
	var/cultplayers = 0
	for(var/mob/player as anything in GLOB.player_list)
		if(player.stat == DEAD)
			continue

		if(IS_CULTIST(player))
			cultplayers++
		else
			alive++

	ASSERT(cultplayers) //we shouldn't be here.

	var/ratio = alive ? cultplayers / alive : 1
	if(ratio > CULT_RISEN && !cult_risen)
		for(var/datum/mind/mind as anything in members)
			if(mind.current)
				SEND_SOUND(mind.current, 'sound/hallucinations/i_see_you2.ogg')
				to_chat(mind.current, span_cultlarge(span_warning("The veil weakens as your cult grows, your eyes begin to glow...")))
				mind.current.AddElement(/datum/element/cult_eyes)
		cult_risen = TRUE
		log_game("The blood cult has risen with [cultplayers] players.")

	if(ratio > CULT_ASCENDENT && !cult_ascendent)
		for(var/datum/mind/mind as anything in members)
			if(mind.current)
				SEND_SOUND(mind.current, 'sound/hallucinations/im_here1.ogg')
				to_chat(mind.current, span_cultlarge(span_warning("Your cult is ascendent and the red harvest approaches - you cannot hide your true nature for much longer!!")))
				mind.current.AddElement(/datum/element/cult_halo/antag_checks)
		cult_ascendent = TRUE
		log_game("The blood cult has ascended with [cultplayers] players.")

/datum/team/cult/add_member(datum/mind/new_member)
	. = ..()
	// A little hacky, but this checks that cult ghosts don't contribute to the size at maximum value.
	if(is_unassigned_job(new_member.assigned_role))
		return
	size_at_maximum++

/datum/team/cult/proc/make_image(datum/objective/sacrifice/sac_objective)
	var/datum/job/job_of_sacrifice = sac_objective.target.assigned_role
	var/datum/preferences/prefs_of_sacrifice = sac_objective.target.current.client.prefs
	var/icon/reshape = get_flat_human_icon(null, job_of_sacrifice, prefs_of_sacrifice, list(SOUTH))
	reshape.Shift(SOUTH, 4)
	reshape.Shift(EAST, 1)
	reshape.Crop(7,4,26,31)
	reshape.Crop(-5,-3,26,30)
	sac_objective.sac_image = reshape

/datum/team/cult/proc/setup_objectives()
	var/datum/objective/sacrifice/sacrifice_objective = new
	sacrifice_objective.team = src
	sacrifice_objective.find_target()
	objectives += sacrifice_objective

	var/datum/objective/eldergod/summon_objective = new
	summon_objective.team = src
	objectives += summon_objective


/datum/team/cult/proc/check_cult_victory()
	for(var/datum/objective/O in objectives)
		if(O.check_completion() == CULT_NARSIE_KILLED)
			return CULT_NARSIE_KILLED
		else if(!O.check_completion())
			return CULT_LOSS
	return CULT_VICTORY

/datum/team/cult/roundend_report()
	var/list/parts = list()
	var/victory = check_cult_victory()

	if(victory == CULT_NARSIE_KILLED) // Epic failure, you summoned your god and then someone killed it.
		parts += "<span class='redtext big'>Nar'sie has been killed! The cult will haunt the universe no longer!</span>"
	else if(victory)
		parts += "<span class='greentext big'>The cult has succeeded! Nar'Sie has snuffed out another torch in the void!</span>"
	else
		parts += "<span class='redtext big'>The staff managed to stop the cult! Dark words and heresy are no match for Nanotrasen's finest!</span>"

	if(objectives.len)
		parts += "<b>The cultists' objectives were:</b>"
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(objective.check_completion())
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] [span_greentext("Success!")]"
			else
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] [span_redtext("Fail.")]"
			count++

	if(members.len)
		parts += "<span class='header'>The cultists were:</span>"
		if(length(true_cultists))
			parts += printplayerlist(true_cultists)
		else
			parts += printplayerlist(members)

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/// Checks if the passed mind is a sacrifice objective target
/datum/team/cult/proc/is_sacrifice_target(datum/mind/mind)
	for(var/datum/objective/sacrifice/sac_objective in objectives)
		if(mind == sac_objective.target)
			return TRUE
	return FALSE

/// Returns whether the given mob is convertable to the blood cult
/proc/is_convertable_to_cult(mob/living/target, datum/team/cult/specific_cult)
	if(!istype(target) || isnull(target.mind))
		return FALSE

#ifndef TESTING
	// Allow clientless mobs with minds to be converted for testing purposes
	if(!GET_CLIENT(target))
		return FALSE
#endif

	if(target.mind.unconvertable)
		return FALSE
	if(ishuman(target) && target.mind.holy_role)
		return FALSE
	if(specific_cult?.is_sacrifice_target(target.mind))
		return FALSE
	var/mob/living/master = target.mind.enslaved_to?.resolve()
	if(master && !IS_CULTIST(master))
		return FALSE
	if(IS_HERETIC_OR_MONSTER(target))
		return FALSE
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD) || issilicon(target) || isbot(target) || isdrone(target))
		return FALSE //can't convert machines, shielded, or braindead

	return TRUE

/// Sets a blood target for the cult.
/datum/team/cult/proc/set_blood_target(atom/new_target, mob/marker, duration = 90 SECONDS)
	if(QDELETED(new_target))
		CRASH("A null or invalid target was passed to set_blood_target.")

	if(duration != INFINITY && blood_target_reset_timer)
		return FALSE

	deltimer(blood_target_reset_timer)
	blood_target = new_target
	RegisterSignal(blood_target, COMSIG_PARENT_QDELETING, PROC_REF(unset_blood_target_and_timer))
	var/area/target_area = get_area(new_target)

	blood_target_image = image('icons/effects/mouse_pointers/cult_target.dmi', new_target, "glow", ABOVE_MOB_LAYER)
	blood_target_image.appearance_flags = RESET_COLOR
	blood_target_image.pixel_x = -new_target.pixel_x
	blood_target_image.pixel_y = -new_target.pixel_y

	for(var/datum/mind/cultist as anything in members)
		if(!cultist.current)
			continue
		if(cultist.current.stat == DEAD || !cultist.current.client)
			continue

		to_chat(cultist.current, span_bold(span_cultlarge("[marker] has marked [blood_target] in the [target_area.name] as the cult's top priority, get there immediately!")))
		SEND_SOUND(cultist.current, sound(pick('sound/hallucinations/over_here2.ogg','sound/hallucinations/over_here3.ogg'), 0, 1, 75))
		cultist.current.client.images += blood_target_image

	if(duration != INFINITY)
		blood_target_reset_timer = addtimer(CALLBACK(src, PROC_REF(unset_blood_target)), duration, TIMER_STOPPABLE)
	return TRUE

/// Unsets out blood target, clearing the images from all the cultists.
/datum/team/cult/proc/unset_blood_target()
	blood_target_reset_timer = null

	for(var/datum/mind/cultist as anything in members)
		if(!cultist.current)
			continue
		if(cultist.current.stat == DEAD || !cultist.current.client)
			continue

		if(QDELETED(blood_target))
			to_chat(cultist.current, span_bold(span_cultlarge("The blood mark's target is lost!")))
		else
			to_chat(cultist.current, span_bold(span_cultlarge("The blood mark has expired!")))
		cultist.current.client.images -= blood_target_image

	UnregisterSignal(blood_target, COMSIG_PARENT_QDELETING)
	blood_target = null

	QDEL_NULL(blood_target_image)

/// Unsets our blood target when they get deleted.
/datum/team/cult/proc/unset_blood_target_and_timer(datum/source)
	SIGNAL_HANDLER

	deltimer(blood_target_reset_timer)
	unset_blood_target()

/**
 * Helper to allow the passed mob to select a possible teleport rune
 */
/datum/team/cult/proc/select_teleport_rune(mob/living/teleporter)
	RETURN_TYPE(/obj/effect/rune/teleport)

	var/list/potential_runes = list()
	var/list/teleportnames = list()
	for(var/obj/effect/rune/teleport/teleport_rune as anything in teleport_runes | GLOB.stray_teleport_runes)
		if(isnull(teleport_rune)) // may sneak in on occasion, working with lazylists
			continue
		potential_runes[avoid_assoc_duplicate_keys(teleport_rune.listkey, teleportnames)] = teleport_rune

	if(!length(potential_runes))
		teleporter.balloon_alert(teleporter, "no valid runes!")
		return

	var/turf/start_turf = get_turf(teleporter)
	if(is_away_level(start_turf.z))
		teleporter.balloon_alert(teleporter, "wrong dimension!")
		return

	var/input_rune_key = tgui_input_list(teleporter, "Rune to teleport to", "Teleportation Target", potential_runes) //we know what key they picked
	if(isnull(input_rune_key) || isnull(potential_runes[input_rune_key]))
		return
	var/obj/effect/rune/teleport/actual_selected_rune = potential_runes[input_rune_key] //what rune does that key correspond to?
	if(QDELETED(src) || QDELETED(teleporter) || QDELETED(teleporter) || QDELETED(actual_selected_rune))
		return
	var/turf/dest = get_turf(actual_selected_rune)
	if(dest.is_blocked_turf(exclude_mobs = TRUE))
		teleporter.balloon_alert(teleporter, "rune blocked!")
		return

	return actual_selected_rune

/datum/outfit/cultist
	name = "Cultist (Preview only)"

	uniform = /obj/item/clothing/under/color/black
	suit = /obj/item/clothing/suit/hooded/cultrobes/alt
	shoes = /obj/item/clothing/shoes/cult/alt
	r_hand = /obj/item/melee/touch_attack/cult/stun

/datum/outfit/cultist/post_equip(mob/living/carbon/human/equipped, visualsOnly)
	equipped.eye_color_left = BLOODCULT_EYE
	equipped.eye_color_right = BLOODCULT_EYE
	equipped.update_body()

#undef CULT_LOSS
#undef CULT_NARSIE_KILLED
#undef CULT_VICTORY
