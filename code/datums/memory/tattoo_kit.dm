
/obj/item/tattoo_kit
	name = "tattoo kit"
	desc = "A kit with all the tools necessary for losing a bet, or making otherwise incredibly indelible decisions."
	icon = 'icons/obj/maintenance_loot.dmi'
	icon_state = "tattoo_kit"
	///each use = 1 tattoo
	var/uses = 1
	///how many uses can be stored
	var/max_uses = 5

/obj/item/tattoo_kit/Initialize(mapload)
	. = ..()
	register_context()

/obj/item/tattoo_kit/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(istype(held_item, /obj/item/toner))
		context[SCREENTIP_CONTEXT_LMB] = "Refill"
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/tattoo_kit/examine(mob/user)
	. = ..()
	if(!uses)
		. += span_warning("This kit has no uses left!")
	else
		. += span_notice("This kit has enough ink for [uses] use\s.")
	. += span_boldnotice("You can use a toner cartridge to refill this.")

/obj/item/tattoo_kit/item_interaction(mob/living/user, obj/item/toner/ink_cart, list/modifiers)
	if(!istype(ink_cart))
		return NONE
	var/added_amount = round(ink_cart.charges / 5)
	if(added_amount == 0)
		balloon_alert(user, "none left!")
		return ITEM_INTERACT_BLOCKING
	if(uses >= max_uses)
		balloon_alert(user, "already full!")
		return ITEM_INTERACT_BLOCKING

	added_amount = min(uses + added_amount, max_uses)
	uses += min(max_uses, added_amount)
	qdel(ink_cart)
	balloon_alert(user, "added tattoo ink")
	return ITEM_INTERACT_SUCCESS

/obj/item/tattoo_kit/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || user.combat_mode || !user.Adjacent(interacting_with)) // telekinesis check
		return NONE

	if(!uses)
		balloon_alert(user, "not enough ink!")
		return ITEM_INTERACT_BLOCKING
	if(!length(user.mind?.memories))
		balloon_alert(user, "nothing memorable to engrave!")
		return ITEM_INTERACT_BLOCKING

	var/selected_zone = user.zone_selected
	var/mob/living/carbon/human/to_tattoo = interacting_with
	var/obj/item/bodypart/tattoo_target = to_tattoo.get_bodypart(selected_zone)
	if(!tattoo_target)
		balloon_alert(user, "no limb to tattoo!")
		return ITEM_INTERACT_BLOCKING
	if(HAS_TRAIT_FROM(tattoo_target, TRAIT_NOT_ENGRAVABLE, ENGRAVED_TRAIT))
		balloon_alert(user, "bodypart already tattooed!")
		return ITEM_INTERACT_BLOCKING
	if(HAS_TRAIT(tattoo_target, TRAIT_NOT_ENGRAVABLE))
		balloon_alert(user, "bodypart cannot be tattooed!")
		return ITEM_INTERACT_BLOCKING
	var/datum/memory/memory_to_tattoo = user.mind.select_memory("tattoo")
	if(!memory_to_tattoo || !user.Adjacent(to_tattoo) || !to_tattoo.get_bodypart(selected_zone))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(span_notice("[user] begins to tattoo something onto [to_tattoo]'s [tattoo_target.plaintext_zone]..."))
	if(!do_after(user, 5 SECONDS, to_tattoo))
		return ITEM_INTERACT_BLOCKING
	if(!to_tattoo.get_bodypart(selected_zone))
		return ITEM_INTERACT_BLOCKING
	tattoo_target.AddComponent(/datum/component/tattoo, memory_to_tattoo.generate_story(STORY_TATTOO))
	//prevent this memory from being used again this round
	memory_to_tattoo.memory_flags |= MEMORY_FLAG_ALREADY_USED
	uses--
	return ITEM_INTERACT_SUCCESS
