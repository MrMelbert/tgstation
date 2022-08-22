/obj/effect/blessing
	name = "holy blessing"
	desc = "Holy energies interfere with ethereal travel at this location."
	icon = 'icons/effects/effects.dmi'
	icon_state = null
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/blessing/Initialize(mapload)
	. = ..()
	for(var/obj/effect/blessing/B in loc)
		if(B != src)
			return INITIALIZE_HINT_QDEL
		var/image/I = image(icon = 'icons/effects/effects.dmi', icon_state = "blessed", layer = ABOVE_OPEN_TURF_LAYER, loc = src)
		I.alpha = 64
		I.appearance_flags = RESET_ALPHA
		add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/blessed_aware, "blessing", I)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_INTERCEPT_TELEPORT = .proc/block_cult_teleport,
		COMSIG_INCORPOREAL_MOVE_CHECK = .proc/block_incorporeal_move,
	)

	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/blessing/proc/block_cult_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER

	if(channel != TELEPORT_CHANNEL_CULT)
		return

	return COMPONENT_BLOCK_TELEPORT

/obj/effect/blessing/proc/block_incorporeal_move(datum/source, mob/mover, incorporeal_move_flags)
	SIGNAL_HANDLER

	if(!(incorporeal_move_flags & INCORPOREAL_MOVE_BLOCKBY_BLESSING))
		return

	to_chat(mover, span_warning("Holy energies block your path!"))
	return BLOCK_INCORPOREAL_MOVE
