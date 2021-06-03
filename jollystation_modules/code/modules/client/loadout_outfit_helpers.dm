/// -- Outfit and mob helpers to equip our loadout items. --

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
			if(!visuals_only && move_to_backpack)
				// Slot one will be a box, usually
				switch(slot)
					if(LOADOUT_ITEM_BACKPACK_1)
						lazyinsert(equipped_outfit.backpack_contents, move_to_backpack, 2)
					if(LOADOUT_ITEM_BACKPACK_2)
						lazyinsert(equipped_outfit.backpack_contents, move_to_backpack, 3)
					if(LOADOUT_ITEM_BACKPACK_3)
						lazyinsert(equipped_outfit.backpack_contents, move_to_backpack, 4)
					else
						LAZYADD(equipped_outfit.backpack_contents, move_to_backpack)

	equipped_outfit.equip(src, visuals_only)
	equip_greyscale(visuals_only, preference_source?.prefs)
	return TRUE

/mob/living/carbon/human/proc/equip_greyscale(visuals_only = FALSE, datum/preferences/preference_source)
	var/list/colors = preference_source?.greyscale_loadout_list
	if(!colors)
		return

	//Start with uniform,suit,backpack for additional slots
	if(w_uniform && colors[LOADOUT_ITEM_UNIFORM])
		w_uniform.set_greyscale(colors[LOADOUT_ITEM_UNIFORM])
	if(wear_suit && colors[LOADOUT_ITEM_SUIT])
		wear_suit.set_greyscale(colors[LOADOUT_ITEM_SUIT])
	if(belt && colors[LOADOUT_ITEM_BELT])
		belt.set_greyscale(colors[LOADOUT_ITEM_BELT])
	if(gloves && colors[LOADOUT_ITEM_GLOVES])
		gloves.set_greyscale(colors[LOADOUT_ITEM_GLOVES])
	if(shoes && colors[LOADOUT_ITEM_SHOES])
		shoes.set_greyscale(colors[LOADOUT_ITEM_SHOES])
	if(head && colors[LOADOUT_ITEM_HEAD])
		head.set_greyscale(colors[LOADOUT_ITEM_HEAD])
	if(wear_mask && colors[LOADOUT_ITEM_MASK])
		wear_mask.set_greyscale(colors[LOADOUT_ITEM_MASK])
	if(wear_neck && colors[LOADOUT_ITEM_NECK])
		wear_neck.set_greyscale(colors[LOADOUT_ITEM_NECK])
	if(ears && colors[LOADOUT_ITEM_EARS])
		ears.set_greyscale(colors[LOADOUT_ITEM_EARS])
	if(glasses && colors[LOADOUT_ITEM_GLASSES])
		glasses.set_greyscale(colors[LOADOUT_ITEM_GLASSES])

	if(!visuals_only && back) // Items in pockets or backpack don't show up on mob's icon.
		for(var/i in 1 to back.contents.len)
			var/obj/item/backpack_item = back.contents[i]
			message_admins("looking for [LOADOUT_ITEM_MISC]_[i-1]")
			if(backpack_item && i > 1 && i < 5 && colors["[LOADOUT_ITEM_MISC]_[i-1]"])
				message_admins("[colors["[LOADOUT_ITEM_MISC]_[i-1]"]] Color found")
				backpack_item.set_greyscale(colors["[LOADOUT_ITEM_MISC]_[i-1]"])

	regenerate_icons()
	return TRUE

/// Insert [item] into the [to_insert] list at [place], or at the end of the list if shorter than place
/proc/lazyinsert(list/to_insert, item, place)
	if(!to_insert)
		to_insert = list()
	if(to_insert.len < place)
		message_admins("Inserting [item] at the end of the list")
		to_insert += item
	else
		message_admins("Inserting [item] at [place] index, list is [to_insert.len] long")
		to_insert.Insert(place, item)
