
/obj/item/bodybag
	name = "body bag"
	desc = "A folded bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag_folded"
	w_class = WEIGHT_CLASS_SMALL
	///Stored path we use for spawning a new body bag entity when unfolded.
	var/unfoldedbag_path = /obj/structure/closet/body_bag

/obj/item/bodybag/attack_self(mob/user)
	if(user.is_holding(src))
		deploy_bodybag(user, get_turf(user))
	else
		deploy_bodybag(user, get_turf(src))

/obj/item/bodybag/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(proximity)
		if(isopenturf(target))
			deploy_bodybag(user, target)

/**
 * Creates a new body bag item when unfolded, at the provided location, replacing the body bag item.
 * * mob/user: User opening the body bag.
 * * atom/location: the place/entity/mob where the body bag is being deployed from.
 */
/obj/item/bodybag/proc/deploy_bodybag(mob/user, atom/location)
	var/obj/structure/closet/body_bag/item_bag = new unfoldedbag_path(location)
	item_bag.open(user)
	item_bag.add_fingerprint(user)
	item_bag.foldedbag_instance = src
	moveToNullspace()
	return item_bag

/obj/item/bodybag/suicide_act(mob/user)
	if(isopenturf(user.loc))
		user.visible_message(span_suicide("[user] is crawling into [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
		var/obj/structure/closet/body_bag/R = new unfoldedbag_path(user.loc)
		R.add_fingerprint(user)
		qdel(src)
		user.forceMove(R)
		playsound(src, 'sound/items/zip.ogg', 15, TRUE, -3)
		return (OXYLOSS)
	..()

// Bluespace bodybag

/obj/item/bodybag/bluespace
	name = "bluespace body bag"
	desc = "A folded bluespace body bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bluebodybag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/bluespace
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NO_MAT_REDEMPTION

/obj/item/bodybag/bluespace/examine(mob/user)
	. = ..()
	if(contents.len <= 0)
		return

	var/plural = contents.len == 1 ? "" : "s"
	. += span_notice("You can make out the shape[plural] of [contents.len] object[plural] through the fabric.")

/obj/item/bodybag/bluespace/deconstruct(disassembled)
	free_contents(message = "You suddenly feel the space around you torn apart! You're free!")
	return ..()

/obj/item/bodybag/bluespace/suicide_act(mob/living/user)
	if(!isliving(user)) // why is suicide_act not casted to living by default ? are there ghosts dying out there
		return

	// No bringing friends to the grave
	free_contents(message = "You tumble out of [src] just as [user] jumps in behind you, alone!")

	// Reference to a bug with BS bags that allowed the user to fold them up while they were inside it. (See: PR #69529)
	user.visible_message(span_suicide("[user] gets inside the bluespace bodybag and starts folding it up while inside! \
		It looks like [user.p_theyre()] about to fold themselves out of existence!"))
	user.dropItemToGround(src, TRUE)
	user.forceMove(src)
	user.Paralyze(2 SECONDS, ignore_canstun = TRUE)
	animate(src, 1 SECONDS, alpha = 0)
	stoplag(1 SECONDS)
	// We got killed during the sleep
	if(QDELETED(src))
		return QDELETED(user) ? MANUAL_SUICIDE : SHAME
	// The user escaped it during the sleep
	if(!(user in contents))
		alpha = 255
		return SHAME

	// You have folded yourself into the bag. Goodbye.
	user.death(TRUE)
	qdel(user)
	// Just in case that some people or items have joined us somehow during the deed.
	deconstruct()
	return MANUAL_SUICIDE

/// Helper to free all of the contents within the bag.
/// You can optionally provide a message that is sent to any living mobs that were located within.
/obj/item/bodybag/bluespace/proc/free_contents(message)
	var/turf/below_us = get_turf(src)
	for(var/atom/movable/thing as anything in contents)
		thing.forceMove(below_us)
		if(isnull(message) || !isliving(thing))
			continue

		to_chat(thing, span_notice(message))

/obj/item/bodybag/bluespace/deploy_bodybag(mob/user, atom/location)
	var/obj/structure/closet/body_bag/item_bag = new unfoldedbag_path(location)
	free_contents(message = "You suddenly feel air around you! You're free!")
	item_bag.open(user)
	item_bag.add_fingerprint(user)
	item_bag.foldedbag_instance = src
	moveToNullspace()
	return item_bag

/obj/item/bodybag/bluespace/container_resist_act(mob/living/user)
	if(user.incapacitated())
		to_chat(user, span_warning("You can't get out while you're restrained like this!"))
		return
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	to_chat(user, span_notice("You claw at the fabric of [src], trying to tear it open..."))
	to_chat(loc, span_warning("Someone starts trying to break free of [src]!"))
	if(!do_mob(user, src, 12 SECONDS, timed_action_flags = (IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM)))
		return
	// you are still in the bag? time to go unless you KO'd, honey!
	// if they escape during this time and you rebag them the timer is still clocking down and does NOT reset so they can very easily get out.
	if(user.incapacitated())
		to_chat(loc, span_warning("The pressure subsides. It seems that they've stopped resisting..."))
		return
	loc.visible_message(span_warning("[user] suddenly appears in front of [loc]!"), span_userdanger("[user] breaks free of [src]!"))
	deconstruct()

/obj/item/bodybag/environmental
	name = "environmental protection bag"
	desc = "A folded, reinforced bag designed to protect against exoplanetary environmental storms."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "envirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/environmental
	w_class = WEIGHT_CLASS_NORMAL //It's reinforced and insulated, like a beefed-up sleeping bag, so it has a higher bulkiness than regular bodybag
	resistance_flags = ACID_PROOF | FIRE_PROOF | FREEZE_PROOF

/obj/item/bodybag/environmental/nanotrasen
	name = "elite environmental protection bag"
	desc = "A folded, heavily reinforced, and insulated bag, capable of fully isolating its contents from external factors."
	icon_state = "ntenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/environmental/nanotrasen
	resistance_flags = ACID_PROOF | FIRE_PROOF | FREEZE_PROOF | LAVA_PROOF

/obj/item/bodybag/environmental/prisoner
	name = "prisoner transport bag"
	desc = "Intended for transport of prisoners through hazardous environments, this folded environmental protection bag comes with straps to keep an occupant secure."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "prisonerenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/environmental/prisoner

/obj/item/bodybag/environmental/prisoner/pressurized
	name = "pressurized prisoner transport bag"
	unfoldedbag_path = /obj/structure/closet/body_bag/environmental/prisoner/pressurized

/obj/item/bodybag/environmental/prisoner/syndicate
	name = "syndicate prisoner transport bag"
	desc = "An alteration of Nanotrasen's environmental protection bag which has been used in several high-profile kidnappings. Designed to keep a victim unconscious, alive, and secured until they are transported to a required location."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "syndieenvirobag_folded"
	unfoldedbag_path = /obj/structure/closet/body_bag/environmental/prisoner/pressurized/syndicate
	resistance_flags = ACID_PROOF | FIRE_PROOF | FREEZE_PROOF | LAVA_PROOF
