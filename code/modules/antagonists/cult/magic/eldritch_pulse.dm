/datum/action/cooldown/spell/pointed/pulse
	name = "Eldritch Pulse"
	desc = "Seize upon a fellow cultist or cult structure and teleport it to a nearby location."
	DEFINE_CULT_ACTION("arcane_barrage", 'icons/mob/actions/actions_spells.dmi')

	sound = null
	cooldown_time = 15 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	active_msg = span_cult("You prepare to tear through the fabric of reality... <b>Click a target to sieze them!</b>")
	deactive_msg = span_cult("You cease your preparations.")
	deactivate_on_failed_cast = FALSE

	// default_button_position = DEFAULT_UNIQUE_BLOODSPELLS
	default_button_position = "5:99,4:30"

	/// Weakref to whoever we're currently about to toss
	var/datum/weakref/throwee_ref

/datum/action/cooldown/spell/pointed/pulse/can_cast_spell(feedback)
	return ..() && IS_CULTIST_MASTER(owner)

/datum/action/cooldown/spell/pointed/pulse/is_valid_target(atom/cast_on)
	return (cast_on in view(cast_range, owner)) // Strict view checks

/datum/action/cooldown/spell/pointed/pulse/proc/grab_target(atom/cast_on)
	active_msg = span_cultbold("You reach through the veil with your mind's eye and [ismob(cast_on) ? "seize" : "lift"] [cast_on]! \
		<b>Click anywhere nearby in view to teleport [cast_on.p_them()]!</b>")

	to_chat(owner, active_msg)
	throwee_ref = WEAKREF(cast_on)
	cast_on.add_filter("eldritch_pulse", 1, list("type" = "outline", "size" = 1, "color" = "#ff3399"))

/datum/action/cooldown/spell/pointed/pulse/proc/drop_target(drop_message = TRUE)
	active_msg = initial(active_msg)
	var/atom/dropped = throwee_ref?.resolve()
	if(dropped)
		dropped.remove_filter("eldritch_pulse")
		if(drop_message)
			to_chat(owner, span_cult("You leave [dropped] alone. <b>Click on another target to seize them.</b>"))
	throwee_ref = null

/datum/action/cooldown/spell/pointed/pulse/before_cast(atom/cast_on)
	. = ..()
	var/atom/existing_target = throwee_ref?.resolve()
	if(existing_target)
		if(existing_target == cast_on)
			drop_target()
			return . | SPELL_CANCEL_CAST

		// Goes to the actual cast
		return

	// Reset any refs, they might be qdeleted mobs
	throwee_ref = null
	// From here on we're either selecting a target or doing nothing at all
	. |= SPELL_CANCEL_CAST

	// We can grab living cultists or cult buildings
	if(isliving(cast_on))
		var/mob/living/living_clicked = cast_on
		if(!IS_CULTIST(living_clicked))
			return
	else if(!istype(cast_on, /obj/structure/destructible/cult))
		return

	grab_target(cast_on)

/datum/action/cooldown/spell/pointed/pulse/cast(atom/cast_on)
	. = ..()
	var/atom/throwee = throwee_ref.resolve()
	if(get_dist(throwee, cast_on) >= cast_range * 2.25) // Two screens and a bit
		to_chat(owner, span_cult("You can't teleport [cast_on.p_them()] that far!"))
		return FALSE

	var/turf/throwee_landing_turf = get_turf(cast_on)
	if(throwee_landing_turf.density)
		return FALSE // Silent failure, should be obviously you can't teleport people into a wall

	// Check that the destination is not covered in dense stuff that gets our guy stuck
	if(throwee_landing_turf.is_blocked_turf(exclude_mobs = TRUE))
		// If there IS dense stuff, check adjacent turfs for any open ones the teleportee can run into after.
		var/any_safe_nearby = FALSE
		for(var/turf/open/by_landing_turf as anything in get_adjacent_open_turfs(throwee_landing_turf))
			any_safe_nearby = by_landing_turf.is_blocked_turf(exclude_mobs = TRUE)
			if(any_safe_nearby)
				break

		// If there is no adjacent open turf without dense things present, it may get them stuck, so stop the teleport.
		if(!any_safe_nearby)
			to_chat(owner, span_cult("Teleporting [cast_on.p_them()] there may trap them!"))
			return FALSE

	var/turf/throwee_turf = get_turf(throwee)

	playsound(throwee_turf, 'sound/magic/exit_blood.ogg')
	new /obj/effect/temp_visual/cult/sparks(throwee_turf, owner.dir)
	throwee.visible_message(
		span_warning("A pulse of magic whisks [throwee] away!"),
		span_cult("A pulse of blood magic whisks you away..."),
	)

	if(!do_teleport(throwee, cast_on, channel = TELEPORT_CHANNEL_CULT))
		to_chat(owner, span_cult("The teleport fails!"))
		throwee.visible_message(
			span_warning("...Except they don't go very far"),
			span_cult("...Except you don't appear to have moved very far."),
		)
		return

	playsound(throwee_landing_turf, 'sound/magic/enter_blood.ogg')
	throwee_turf.Beam(throwee_landing_turf, icon_state = "sendbeam", time = 0.4 SECONDS)
	new /obj/effect/temp_visual/cult/sparks(throwee_landing_turf, owner.dir)
	throwee.visible_message(
		span_warning("[throwee] appears suddenly in a pulse of magic!"),
		span_cult("...And you appear elsewhere."),
	)

	to_chat(owner, span_cult("A pulse of blood magic surges through you as you shift [throwee] through time and space."))
	drop_target(drop_message = FALSE)
