/obj/item/gun/medbeam
	name = "Medical Beamgun"
	desc = "Don't cross the streams!"
	icon = 'icons/obj/chronos.dmi'
	icon_state = "chronogun"
	inhand_icon_state = "chronogun"
	w_class = WEIGHT_CLASS_NORMAL

	var/mob/living/current_target
	var/last_check = 0
	var/check_delay = 10 //Check los as often as possible, max resolution is SSobj tick though
	var/max_range = 8
	var/active = FALSE
	var/datum/beam/current_beam = null
	var/mounted = 0 //Denotes if this is a handheld or mounted version

	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/medbeam/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/gun/medbeam/Destroy(mob/user)
	STOP_PROCESSING(SSobj, src)
	LoseTarget()
	return ..()

/obj/item/gun/medbeam/dropped(mob/user)
	..()
	LoseTarget()

/obj/item/gun/medbeam/equipped(mob/user)
	..()
	LoseTarget()

/**
 * Proc that always is called when we want to end the beam and makes sure things are cleaned up, see beam_died()
 */
/obj/item/gun/medbeam/proc/LoseTarget()
	if(active)
		QDEL_NULL(current_beam)
		active = FALSE
		on_beam_release(current_target)
	current_target = null

/**
 * Proc that is only called when the beam fails due to something, so not when manually ended.
 * manual disconnection = LoseTarget, so it can silently end
 * automatic disconnection = beam_died, so we can give a warning message first
 */
/obj/item/gun/medbeam/proc/beam_died()
	SIGNAL_HANDLER
	current_beam = null
	active = FALSE //skip qdelling the beam again if we're doing this proc, because
	if(isliving(loc))
		to_chat(loc, span_warning("You lose control of the beam!"))
	LoseTarget()

/obj/item/gun/medbeam/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(isliving(user))
		add_fingerprint(user)

	if(current_target)
		LoseTarget()
	if(!isliving(target))
		return

	current_target = target
	active = TRUE
	current_beam = user.Beam(current_target, icon_state="medbeam", time = 10 MINUTES, maxdistance = max_range, beam_type = /obj/effect/ebeam/medical)
	RegisterSignal(current_beam, COMSIG_QDELETING, PROC_REF(beam_died))//this is a WAY better rangecheck than what was done before (process check)

	SSblackbox.record_feedback("tally", "gun_fired", 1, type)

/obj/item/gun/medbeam/process()
	if(!mounted && !isliving(loc))
		LoseTarget()
		return

	if(!current_target)
		LoseTarget()
		return

	if(world.time <= last_check+check_delay)
		return

	last_check = world.time

	if(!los_check(loc, current_target))
		QDEL_NULL(current_beam)//this will give the target lost message
		return

	if(current_target)
		on_beam_tick(current_target)

/obj/item/gun/medbeam/proc/los_check(atom/movable/user, mob/target)
	var/turf/user_turf = user.loc
	if(mounted)
		user_turf = get_turf(user)
	else if(!istype(user_turf))
		return FALSE
	var/obj/dummy = new(user_turf)
	dummy.pass_flags |= PASSTABLE|PASSGLASS|PASSGRILLE //Grille/Glass so it can be used through common windows
	var/turf/previous_step = user_turf
	var/first_step = TRUE
	for(var/turf/next_step as anything in (get_line(user_turf, target) - user_turf))
		if(first_step)
			for(var/obj/blocker in user_turf)
				if(!blocker.density || !(blocker.flags_1 & ON_BORDER_1))
					continue
				if(blocker.CanPass(dummy, get_dir(user_turf, next_step)))
					continue
				return FALSE // Could not leave the first turf.
			first_step = FALSE
		if(mounted && next_step == user_turf)

			continue //Mechs are dense and thus fail the check
		if(next_step.density)
			qdel(dummy)
			return FALSE
		for(var/atom/movable/movable as anything in next_step)
			if(!movable.CanPass(dummy, get_dir(next_step, previous_step)))
				qdel(dummy)
				return FALSE
		for(var/obj/effect/ebeam/medical/rival_beam in next_step)// Don't cross the str-beams!
			if(QDELETED(current_beam))
				break //We shouldn't be processing anymore.
			if(QDELETED(rival_beam))
				continue
			if(!rival_beam.owner)
				stack_trace("beam without an owner! [rival_beam]")
				continue
			if(rival_beam.owner.origin != current_beam.origin)
				var/mob/living/beamer_one = mounted ? (locate(/mob/living) in rival_beam.owner.origin) : get(rival_beam.owner.origin, /mob/living)
				var/mob/living/beamer_two = mounted ? (locate(/mob/living) in current_beam.origin) : get(current_beam.origin,  /mob/living)
				// Achievements are only handed out if two people consciously make the same error
				if(beamer_one?.key && beamer_two?.key)
					beamer_one.client?.give_award(/datum/award/achievement/misc/crossed_beams, beamer_one)
					beamer_two.client?.give_award(/datum/award/achievement/misc/crossed_beams, beamer_two)

				// The moment before disaster.
				if(beamer_one)
					to_chat(beamer_one, span_userdanger("As you observe your medbeam cross directly through another, you feel as though you fucked up."))
				if(beamer_two)
					to_chat(beamer_two, span_userdanger("As you observe your medbeam cross directly through another, you feel as though you fucked up."))
				next_step.visible_message(span_warning("The medbeams cross directly through one another, causing a bright flash!"))

				log_bomber("[beamer_one || rival_beam.owner.origin] and [beamer_two || current_beam.origin] crossed the beams at [AREACOORD(next_step)].")
				message_admins("[ADMIN_LOOKUPFLW(beamer_one || rival_beam.owner.origin)] and [ADMIN_LOOKUPFLW(beamer_two || current_beam.origin)] crossed the beams at [ADMIN_VERBOSEJMP(next_step)].")
				explosion(next_step, heavy_impact_range = 3, light_impact_range = 5, flash_range = 8, explosion_cause = src)
				qdel(dummy)
				return FALSE
		previous_step = next_step
	qdel(dummy)
	return TRUE

/obj/item/gun/medbeam/proc/on_beam_hit(mob/living/target)
	return

/obj/item/gun/medbeam/proc/on_beam_tick(mob/living/target)
	if(target.health != target.maxHealth)
		new /obj/effect/temp_visual/heal(get_turf(target), COLOR_HEALING_CYAN)
	target.adjustBruteLoss(-4)
	target.adjustFireLoss(-4)
	target.adjustToxLoss(-1, forced = TRUE)
	target.adjustOxyLoss(-1, forced = TRUE)
	return

/obj/item/gun/medbeam/proc/on_beam_release(mob/living/target)
	return

/obj/effect/ebeam/medical
	name = "medical beam"

//////////////////////////////Mech Version///////////////////////////////
/obj/item/gun/medbeam/mech
	mounted = TRUE

/obj/item/gun/medbeam/mech/Initialize(mapload)
	. = ..()
	STOP_PROCESSING(SSobj, src) //Mech mediguns do not process until installed, and are controlled by the holder obj
