/// -- Outfit and mob helpers to equip our loadout items. --

#define LAZYINSERT(L, I, P) if(!L) { L = list(); } L.Insert(P, I);

/// An empty outfit we fill in with our loadout items to dress our dummy.
/datum/outfit/player_loadout
	name = "Player Loadout"

/* Actually equip our mob with our job outfit and our loadout items.
 * Loadout items override the pre-existing item in the corresponding slot of the job outfit.
 * Some job items are preserved after being overridden - belt items, ear items, and glasses.
 * The rest of the slots, the items are overridden completely and deleted.
 *
 * Plasmamen are snowflaked to not have any envirosuit pieces removed just in case.
 * Their loadout items for those slots will be added to their backpack on spawn.
 *
 * outfit - the job outfit we're equipping
 * visuals_only - whether we call special equipped procs, or if we just look like we equipped it
 * preference_source - the client belonging to the thing we're equipping
 */
/mob/living/carbon/human/proc/equip_outfit_and_loadout(datum/outfit/outfit, visuals_only = FALSE, client/preference_source)
	var/datum/outfit/equipped_outfit

	if(ispath(outfit))
		equipped_outfit = new outfit()
	else if(istype(outfit))
		equipped_outfit = outfit
	else
		return FALSE

	if(LAZYLEN(preference_source?.prefs?.loadout_list))
		var/list/loadout = preference_source?.prefs?.loadout_list
		for(var/slot in loadout)
			var/move_to_backpack = null
			switch(slot)
				if(LOADOUT_ITEM_BELT)
					if(equipped_outfit.belt)
						move_to_backpack = equipped_outfit.belt
					equipped_outfit.belt = loadout[slot]
				if(LOADOUT_ITEM_EARS)
					if(equipped_outfit.ears)
						move_to_backpack = equipped_outfit.ears
					equipped_outfit.ears = loadout[slot]
				if(LOADOUT_ITEM_GLASSES)
					if(equipped_outfit.glasses)
						move_to_backpack = equipped_outfit.glasses
					equipped_outfit.glasses = loadout[slot]
				if(LOADOUT_ITEM_GLOVES)
					if(isplasmaman(src))
						to_chat(src, "Your loadout gloves were not equipped directly due to your envirosuit gloves.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.gloves = loadout[slot]
				if(LOADOUT_ITEM_HEAD)
					if(isplasmaman(src))
						to_chat(src, "Your loadout helmet was not equipped directly due to your envirosuit helmet.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.head = loadout[slot]
				if(LOADOUT_ITEM_MASK)
					if(isplasmaman(src))
						move_to_backpack = loadout[slot]
						to_chat(src, "Your loadout mask was not equipped directly due to your envirosuit mask.")
					else
						equipped_outfit.mask = loadout[slot]
				if(LOADOUT_ITEM_NECK)
					equipped_outfit.neck = loadout[slot]
				if(LOADOUT_ITEM_SHOES)
					equipped_outfit.shoes = loadout[slot]
				if(LOADOUT_ITEM_SUIT)
					equipped_outfit.suit = loadout[slot]
				if(LOADOUT_ITEM_UNIFORM)
					if(isplasmaman(src))
						to_chat(src, "Your loadout jumpsuit was not equipped directly due to your envirosuit.")
						move_to_backpack = loadout[slot]
					else
						equipped_outfit.uniform = loadout[slot]
				if(LOADOUT_ITEM_LEFT_HAND)
					if(equipped_outfit.l_hand)
						move_to_backpack = equipped_outfit.l_hand
					equipped_outfit.l_hand = loadout[slot]
				if(LOADOUT_ITEM_RIGHT_HAND)
					if(equipped_outfit.r_hand)
						move_to_backpack = equipped_outfit.r_hand
					equipped_outfit.r_hand = loadout[slot]
				if(LOADOUT_ITEM_BACKPACK_1, LOADOUT_ITEM_BACKPACK_2, LOADOUT_ITEM_BACKPACK_3)
					if(ispath(loadout[slot], /obj/item/clothing/accessory))
						if(equipped_outfit.accessory)
							move_to_backpack = equipped_outfit.accessory
						equipped_outfit.accessory = loadout[slot]
					else
						move_to_backpack = loadout[slot]
				else
					move_to_backpack = loadout[slot]
			if(move_to_backpack)
				switch(slot)
					if(LOADOUT_ITEM_BACKPACK_1)
						LAZYINSERT(equipped_outfit.backpack_contents, move_to_backpack, 1)
					if(LOADOUT_ITEM_BACKPACK_2)
						LAZYINSERT(equipped_outfit.backpack_contents, move_to_backpack, 2)
					if(LOADOUT_ITEM_BACKPACK_3)
						LAZYINSERT(equipped_outfit.backpack_contents, move_to_backpack, 3)
					else
						LAZYADD(equipped_outfit.backpack_contents, move_to_backpack)

	return equipped_outfit.equip_and_greyscale(src, visuals_only, preference_source?.prefs?.greyscale_loadout_list)

/* Equip our outfit and greyscale anything that needs to be greyscaled.
 *
 * equipped_human - the mob we're equipping items onto
 * visuals_only - whether we call special equipped procs, or if we just look like we equipped it
 * colors - an assoc list of all greyscale color configs we have per item
 */
/datum/outfit/proc/equip_and_greyscale(mob/living/carbon/human/equipped_human, visualsOnly = FALSE, list/colors)
	pre_equip(equipped_human, visualsOnly)

	//Start with uniform,suit,backpack for additional slots
	if(uniform)
		var/obj/item/equipped_uniform = new uniform(equipped_human)
		if(colors && colors[LOADOUT_ITEM_UNIFORM])
			equipped_uniform.set_greyscale(colors[LOADOUT_ITEM_UNIFORM])
		equipped_human.equip_to_slot_or_del(equipped_uniform, ITEM_SLOT_ICLOTHING, TRUE)
	if(suit)
		var/obj/item/equipped_suit = new suit(equipped_human)
		if(colors && colors[LOADOUT_ITEM_SUIT])
			equipped_suit.set_greyscale(colors[LOADOUT_ITEM_SUIT])
		equipped_human.equip_to_slot_or_del(equipped_suit, ITEM_SLOT_OCLOTHING, TRUE)
	if(back)
		equipped_human.equip_to_slot_or_del(new back(equipped_human), ITEM_SLOT_BACK, TRUE)
	if(belt)
		var/obj/item/equipped_belt = new belt(equipped_human)
		if(colors && colors[LOADOUT_ITEM_BELT])
			equipped_belt.set_greyscale(colors[LOADOUT_ITEM_BELT])
		equipped_human.equip_to_slot_or_del(equipped_belt, ITEM_SLOT_BELT, TRUE)
	if(gloves)
		var/obj/item/equipped_gloves = new gloves(equipped_human)
		if(colors && colors[LOADOUT_ITEM_GLOVES])
			equipped_gloves.set_greyscale(colors[LOADOUT_ITEM_GLOVES])
		equipped_human.equip_to_slot_or_del(equipped_gloves, ITEM_SLOT_GLOVES, TRUE)
	if(shoes)
		var/obj/item/equipped_shoes = new shoes(equipped_human)
		if(colors && colors[LOADOUT_ITEM_SHOES])
			equipped_shoes.set_greyscale(colors[LOADOUT_ITEM_SHOES])
		equipped_human.equip_to_slot_or_del(equipped_shoes, ITEM_SLOT_FEET, TRUE)
	if(head)
		var/obj/item/equipped_hat = new head(equipped_human)
		if(colors && colors[LOADOUT_ITEM_HEAD])
			equipped_hat.set_greyscale(colors[LOADOUT_ITEM_HEAD])
		equipped_human.equip_to_slot_or_del(equipped_hat, ITEM_SLOT_HEAD, TRUE)
	if(mask)
		var/obj/item/equipped_mask = new mask(equipped_human)
		if(colors && colors[LOADOUT_ITEM_MASK])
			equipped_mask.set_greyscale(colors[LOADOUT_ITEM_MASK])
		equipped_human.equip_to_slot_or_del(equipped_mask, ITEM_SLOT_MASK, TRUE)
	if(neck)
		var/obj/item/equipped_neck = new neck(equipped_human)
		if(colors && colors[LOADOUT_ITEM_NECK])
			equipped_neck.set_greyscale(colors[LOADOUT_ITEM_NECK])
		equipped_human.equip_to_slot_or_del(equipped_neck, ITEM_SLOT_NECK, TRUE)
	if(ears)
		var/obj/item/equipped_ears = new ears(equipped_human)
		if(colors && colors[LOADOUT_ITEM_EARS])
			equipped_ears.set_greyscale(colors[LOADOUT_ITEM_EARS])
		equipped_human.equip_to_slot_or_del(equipped_ears, ITEM_SLOT_EARS, TRUE)
	if(glasses)
		var/obj/item/equipped_glasses = new glasses(equipped_human)
		if(colors && colors[LOADOUT_ITEM_GLASSES])
			equipped_glasses.set_greyscale(colors[LOADOUT_ITEM_GLASSES])
		equipped_human.equip_to_slot_or_del(equipped_glasses, ITEM_SLOT_EYES, TRUE)

	if(id)
		equipped_human.equip_to_slot_or_del(new id(equipped_human), ITEM_SLOT_ID, TRUE)

	if(!visualsOnly && id_trim && equipped_human.wear_id)
		var/obj/item/card/id/id_card = equipped_human.wear_id
		if(istype(id_card) && !SSid_access.apply_trim_to_card(id_card, id_trim))
			WARNING("Unable to apply trim [id_trim] to [id_card] in outfit [name].")

	if(suit_store)
		equipped_human.equip_to_slot_or_del(new suit_store(equipped_human), ITEM_SLOT_SUITSTORE, TRUE)

	if(undershirt)
		equipped_human.undershirt = initial(undershirt.name)

	if(accessory)
		var/obj/item/clothing/under/our_uniform = equipped_human.w_uniform
		if(our_uniform)
			our_uniform.attach_accessory(new accessory(our_uniform))
		else
			LAZYADD(backpack_contents, accessory)
			WARNING("Unable to equip accessory [accessory] in outfit [name]. No uniform present!")

	if(l_hand)
		equipped_human.put_in_l_hand(new l_hand(equipped_human))
	if(r_hand)
		equipped_human.put_in_r_hand(new r_hand(equipped_human))

	if(!visualsOnly) // Items in pockets or backpack don't show up on mob's icon.
		if(l_pocket)
			equipped_human.equip_to_slot_or_del(new l_pocket(equipped_human), ITEM_SLOT_LPOCKET, TRUE)
		if(r_pocket)
			equipped_human.equip_to_slot_or_del(new r_pocket(equipped_human), ITEM_SLOT_RPOCKET, TRUE)

		if(box)
			if(!backpack_contents)
				backpack_contents = list()
			backpack_contents.Insert(1, box)
			backpack_contents[box] = 1

		if(backpack_contents)
			// The number of backpack items we have, not including the box
			var/num_backpack_items = box ? 0 : 1
			for(var/path in backpack_contents)
				var/number = backpack_contents[path]
				if(!isnum(number))//Default to 1
					number = 1
				for(var/i in 1 to number)
					var/obj/item/equipped_backpack_item = new path(equipped_human)
					if(num_backpack_items > 0 && num_backpack_items < 4)
						if(colors && colors["[LOADOUT_ITEM_MISC]_[num_backpack_items]"])
							equipped_backpack_item.set_greyscale(colors["[LOADOUT_ITEM_MISC]_[num_backpack_items]"])
					equipped_human.equip_to_slot_or_del(quipped_backpack_item, ITEM_SLOT_BACKPACK, TRUE)
				num_backpack_items++

	if(!equipped_human.head && toggle_helmet && istype(equipped_human.wear_suit, /obj/item/clothing/suit/space/hardsuit))
		var/obj/item/clothing/suit/space/hardsuit/equipped_hardsuit = equipped_human.wear_suit
		equipped_hardsuit.ToggleHelmet()

	post_equip(equipped_human, visualsOnly)

	if(!visualsOnly)
		apply_fingerprints(equipped_human)
		if(internals_slot)
			equipped_human.internal = equipped_human.get_item_by_slot(internals_slot)
			equipped_human.update_action_buttons_icon()
		if(implants)
			for(var/implant_type in implants)
				var/obj/item/implant/equipped_implant = new implant_type(equipped_human)
				equipped_implant.implant(equipped_human, null, TRUE)

		// Insert the skillchips associated with this outfit into the target.
		if(skillchips)
			for(var/skillchip_path in skillchips)
				var/obj/item/skillchip/skillchip_instance = new skillchip_path()
				var/implant_msg = equipped_human.implant_skillchip(skillchip_instance)
				if(implant_msg)
					stack_trace("Failed to implant [equipped_human] with [skillchip_instance], on job [src]. Failure message: [implant_msg]")
					qdel(skillchip_instance)
					return

				var/activate_msg = skillchip_instance.try_activate_skillchip(TRUE, TRUE)
				if(activate_msg)
					CRASH("Failed to activate [equipped_human]'s [skillchip_instance], on job [src]. Failure message: [activate_msg]")


	equipped_human.update_body()
	return TRUE
