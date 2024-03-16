/obj/item/stack/telecrystal
	name = "telecrystal"
	desc = "It seems to be pulsing with suspiciously enticing energies."
	singular_name = "telecrystal"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "telecrystal"
	dye_color = DYE_SYNDICATE
	w_class = WEIGHT_CLASS_TINY
	max_amount = 50
	item_flags = NOBLUDGEON
	merge_type = /obj/item/stack/telecrystal
	novariants = FALSE

/obj/item/stack/telecrystal/interact_with_atom(atom/interacting_with, mob/living/user)
	if(interacting_with != user) //You can't go around smacking people with crystals to find out if they have an uplink or not.
		return NONE

	for(var/obj/item/implant/uplink/uplink in interacting_with)
		if(!uplink.imp_in)
			continue

		var/datum/component/uplink/hidden_uplink = uplink.GetComponent(/datum/component/uplink)
		if(hidden_uplink)
			hidden_uplink.uplink_handler.add_telecrystals(amount)
			use(amount)
			to_chat(user, span_notice("You press [src] onto yourself and charge your hidden uplink."))
			return ITEM_INTERACT_SUCCESS

	return ITEM_INTERACT_BLOCKING

// Stacks don't call parent on attack self because they are cringe
/obj/item/stack/telecrystal/attack_self(mob/user, modifiers)
	if(loc != user) // Telekinesis moment
		return TRUE

	user.visible_message(
		span_warning("[user] crushes [src]!"),
		span_danger("You crush [src]!"),
	)
	playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	do_teleport(
		teleatom = user,
		destination = get_ranged_target_turf(user, user.dir, 2),
		precision = 4,
		asoundin = 'sound/effects/phasein.ogg',
		channel = TELEPORT_CHANNEL_QUANTUM,
	)
	use(1)
	return TRUE

/obj/item/stack/telecrystal/five
	amount = 5

/obj/item/stack/telecrystal/twenty
	amount = 20
