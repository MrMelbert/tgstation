/datum/element/airlock_prying
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2

	/// If TRUE, a more detailed balloon alert will be displayed on failure to pry.
	/// If FALSE, a generic "It won't budge!" will display instead.
	var/detailed_failure_descriptions = TRUE
	/// If attached to a mob, this is what is shown in the visible message
	/// as what they are "using" to pry open the airlock
	var/mob_pry_noun = "hands"
	/// Sound to play when a depowered airlock is pried open
	var/depowered_pry_sound
	/// Sound to play when a powered airlock is pried open
	var/powered_pry_sound = 'sound/machines/airlock_alien_prying.ogg'
	/// If TRUE, we can pry open depowered airlocks.
	/// You may want to set this to FALSE if your pryer is something that can already do that, like a crowbar.
	var/pry_depowered = TRUE
	/// How long it takes to pry open a door
	var/pry_time = 2 SECONDS
	/// How long it takes to pry open a depowered door, requires [pry_depowered]
	var/pry_time_unpowered = 0.5 SECONDS
	/// Optional proc call used to check for specific things prior to prying
	var/try_pry_proccall

/datum/element/airlock_prying/Attach(
	datum/target,
	detailed_failure_descriptions = TRUE,
	mob_pry_noun = "hands",
	depowered_pry_sound,
	powered_pry_sound = 'sound/machines/airlock_alien_prying.ogg',
	pry_depowered = TRUE,
	pry_time = 2 SECONDS,
	pry_time_unpowered = 0.5 SECONDS,
	try_pry_proccall,
)

	. = ..()
	if(isliving(target))
		RegisterSignal(target, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	else if(isitem(target))
		RegisterSignal(target, COMSIG_ITEM_PRE_ATTACK, PROC_REF(on_pre_attack))
	else
		return ELEMENT_INCOMPATIBLE

	src.detailed_failure_descriptions = detailed_failure_descriptions
	src.mob_pry_noun = mob_pry_noun
	src.depowered_pry_sound = depowered_pry_sound
	src.powered_pry_sound = powered_pry_sound
	src.pry_depowered = pry_depowered
	src.pry_time = pry_time
	src.pry_time_unpowered = pry_time_unpowered
	src.try_pry_proccall = try_pry_proccall

/datum/element/airlock_prying/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ITEM_PRE_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))

/datum/element/airlock_prying/proc/on_pre_attack(obj/item/source, atom/attacked, mob/living/attacker, params)
	SIGNAL_HANDLER

	if(!try_pry(attacked, attacker, source))
		return

	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/element/airlock_prying/proc/on_unarmed_attack(mob/living/source, atom/attacked, proximity, list/modifiers)
	SIGNAL_HANDLER

	if(!proximity)
		return
	if(!try_pry(attacked, source))
		return

	return COMPONENT_CANCEL_ATTACK_CHAIN


/datum/element/airlock_prying/proc/try_pry(atom/possible_door, mob/living/pryer, obj/item/prybar)
	if(!istype(possible_door, /obj/machinery/door))
		return FALSE

	var/obj/machinery/door/door = possible_door
	var/obj/machinery/door/airlock/airlock_door = possible_door // Because some vars we check are on airlock
	// No density = Already open
	// Always allow combat mode to hit doors
	if(!door.density || door.operating || pryer.combat_mode)
		return FALSE
	if(door.hasPower())
		// Door is powered and, if the door's gonna open anyways, let's not try to pry it
		if(!door.requiresID() || door.allowed(pryer))
			return FALSE
	else
		// Door is unpowered and we don't open unpowered stuff
		if(!pry_depowered)
			return FALSE

	if(door.resistance_flags & INDESTRUCTIBLE)
		door.balloon_alert(pryer, "too strong!")
		return FALSE

	var/generic_failure_description = "won't budge!"
	if(door.locked)
		door.balloon_alert(pryer, detailed_failure_descriptions ? "it's bolted shut!" : generic_failure_description)
		return FALSE
	if(door.welded)
		door.balloon_alert(pryer, detailed_failure_descriptions ? "it's welded shut!" : generic_failure_description)
		return FALSE
	if(istype(airlock_door) && airlock_door.seal)
		door.balloon_alert(pryer, detailed_failure_descriptions ? "it's sealed shut!" : generic_failure_description)
		return FALSE
	if(try_pry_proccall && !call(prybar || pryer, try_pry_proccall)(arglist(args)))
		return FALSE

	INVOKE_ASYNC(src, PROC_REF(pry_door), door, pryer, prybar)
	return TRUE

/datum/element/airlock_prying/proc/pry_door(obj/machinery/door/door, mob/living/pryer, obj/item/prybar)
	if(!prybar)
		door.add_fingerprint(pryer)

	// Like sticking a fork in an electric socket
	if(!evade_shock_from_door(door, pryer, prybar))
		return FALSE

	do_sparks(3, TRUE, door)
	door.balloon_alert(pryer, "prying open...")
	pryer.visible_message(
		span_warning("[pryer] begins prying open [src] with [pryer.p_their()] [prybar ? "[prybar.name]" : "[mob_pry_noun]"]..."),
		span_hear("You hear groaning metal..."),
		ignored_mobs = pryer,
	)

	var/powered = door.hasPower()
	playsound(door, powered ? powered_pry_sound : depowered_pry_sound, 100, TRUE)
	var/final_pry_time = powered ? pry_time : pry_time_unpowered
	// Pod doors are stronger and take longer to cut through
	if(istype(door, /obj/machinery/door/poddoor))
		final_pry_time *= 3
	var/shock_callback = CALLBACK(src, PROC_REF(evade_shock_from_door), door, pryer, prybar)
	if(final_pry_time > 0 SECONDS && !do_after(pryer, final_pry_time, door, extra_checks = shock_callback))
		door.balloon_alert(pryer, "interrupted!")
		return FALSE

	if(door.density && !door.open(BYPASS_DOOR_CHECKS))
		// The airlock is still closed, maybe someone prevented the pry last second (like by bolting or welding the door).
		door.balloon_alert(pryer, "prying failed!")
		return FALSE

	if(check_holidays(APRIL_FOOLS) && prob(10))
		pryer.say("Heeeeeeeeeerrre's Johnny!")

	door.balloon_alert(pryer, "pried")
	pryer.visible_message(
		span_warning("[pryer] pries open [src] with [pryer.p_their()] [prybar ? "[prybar.name]" : "[mob_pry_noun]"]!"),
		blind_message = span_hear("You hear a metal screeching sound."),
		ignored_mobs = pryer,
	)
	door.take_damage(25, BRUTE, sound_effect = FALSE) // Enough to sometimes spark
	return TRUE

/datum/element/airlock_prying/proc/evade_shock_from_door(obj/machinery/door/airlock/door, mob/living/pryer, obj/item/prybar)
	if(!istype(door))
		return TRUE
	// Like sticking a fork in an electric socket
	if(door.isElectrified() && (!prybar || (prybar.flags_1 & CONDUCT_1)) && door.shock(pryer, 100))
		return FALSE
	return TRUE
