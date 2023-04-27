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
	for(var/obj/effect/blessing/existing_blessing in loc)
		if(existing_blessing != src)
			return INITIALIZE_HINT_QDEL
		var/image/bless_image = image(icon = 'icons/effects/effects.dmi', icon_state = "blessed", layer = ABOVE_OPEN_TURF_LAYER, loc = src)
		bless_image.alpha = 64
		bless_image.appearance_flags = RESET_ALPHA
		add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/blessed_aware, "blessing", bless_image)

	var/static/list/loc_connections = list(COMSIG_ATOM_INTERCEPT_TELEPORTING = PROC_REF(block_cult_teleport))
	AddElement(/datum/element/connect_loc, loc_connections)
	AddElement(/datum/element/trait_loc, TRAIT_HOLY)

/obj/effect/blessing/proc/block_cult_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER

	if(channel == TELEPORT_CHANNEL_CULT)
		return COMPONENT_BLOCK_TELEPORT
