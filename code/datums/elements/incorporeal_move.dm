/// This mob can walk through walls incorporeally.
/datum/element/move_incorporeally
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	/// Flags used when checking if an incorporeal move is possible.
	var/incorporeal_move_flags = NONE

/datum/element/move_incorporeally/Attach(datum/target, incorporeal_move_flags = NONE)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE

	src.incorporeal_move_flags = incorporeal_move_flags
	RegisterSignal(target, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, .proc/on_pre_living_move)

	target.AddElement(/datum/element/movetype_handler)
	ADD_TRAIT(target, TRAIT_MOVE_FLOATING, ELEMENT_TRAIT(type))
	ADD_TRAIT(target, TRAIT_INCORPOREALLY_MOVING, ELEMENT_TRAIT(type))

/datum/element/move_incorporeally/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE)

	source.RemoveElement(/datum/element/movetype_handler)
	REMOVE_TRAIT(source, TRAIT_MOVE_FLOATING, ELEMENT_TRAIT(type))
	REMOVE_TRAIT(source, TRAIT_INCORPOREALLY_MOVING, ELEMENT_TRAIT(type))

/// Signal proc for [COMSIG_MOB_CLIENT_PRE_LIVING_MOVE].
/datum/element/move_incorporeally/proc/on_pre_living_move(mob/living/source, direction)
	SIGNAL_HANDLER

	var/turf/move_to_turf = get_step(source, direction)
	if(move_to_turf)
		if(is_secret_level(move_to_turf.z))
			return
		if(!source.incorporeal_move_check(move_to_turf, incorporeal_move_flags = incorporeal_move_flags))
			return
		source.forceMove(move_to_turf)
	source.setDir(direction)

	return COMSIG_MOB_CLIENT_BLOCK_PRE_LIVING_MOVE

/// Checks if this mob can incorporeally move to a certain turf with the passed set of flags.
/// This is on the living level instead of on the element because some things which are not incorporeally moving currently
/// or that cannot incorporeally move (such as objects) may need to know if an incorporeal move is theoretically possible.
/mob/living/proc/incorporeal_move_check(turf/destination, incorporeal_move_flags = NONE)
	if(SEND_SIGNAL(destination, COMSIG_INCORPOREAL_MOVE_CHECK, src, incorporeal_move_flags) & BLOCK_INCORPOREAL_MOVE)
		return FALSE

	if(incorporeal_move_flags & INCORPOREAL_MOVE_RESPECT_NOJAUNT)
		if(destination.turf_flags & NOJAUNT)
			to_chat(src, span_warning("Some strange aura is blocking the way."))
			return FALSE

		var/area/destination_area = get_area(destination)
		if(destination_area.area_flags & NOTELEPORT || SSmapping.level_trait(destination.z, ZTRAIT_NOPHASE))
			to_chat(src, span_danger("Some dull, universal force is blocking the way. It's overwhelmingly oppressive force feels dangerous."))
			return FALSE

	return TRUE
