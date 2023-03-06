
/datum/action/item_action/cult_dagger
	name = "Draw Blood Rune"
	desc = "Use the ritual dagger to create a powerful blood rune"
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "draw"
	buttontooltipstyle = "cult"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"

	// default_button_position = "6:157,4:-2"

/datum/action/item_action/cult_dagger/Grant(mob/grant_to)
	var/datum/antagonist/cult/cultist = IS_CULTIST(grant_to)
	if(isnull(cultist))
		return

	. = ..()

	if(!owner || owner != grant_to)
		return
	if(default_button_position != SCRN_OBJ_IN_LIST)
		return

	for(var/datum/hud/hud as anything in viewers)
		var/atom/movable/screen/movable/action_button/moving_button = viewers[hud]
		if(!moving_button)
			continue

		var/our_view = hud.mymob?.client?.view || "15x15"
		var/base_pos = screen_loc_to_offset(DEFAULT_BLOODSPELLS)
		// The rune carving action will alawys be shifted to the furthest spot on the spell bar
		var/rune_x = base_pos[1] + (cultist.magic_holder.empowered_spell_limit + 1) * world.icon_size
		var/newpos = offset_to_screen_loc(rune_x, base_pos[2], our_view)
		hud.position_action(moving_button, newpos)
		default_button_position = newpos // Update default position

/datum/action/item_action/cult_dagger/Trigger(trigger_flags)
	for(var/obj/item/held_item as anything in owner.held_items) // In case we were already holding a dagger
		if(istype(held_item, /obj/item/melee/cultblade/dagger))
			held_item.attack_self(owner)
			return
	var/obj/item/target_item = target
	if(owner.can_equip(target_item, ITEM_SLOT_HANDS))
		owner.temporarilyRemoveItemFromInventory(target_item)
		owner.put_in_hands(target_item)
		target_item.attack_self(owner)
		return

	if(!isliving(owner))
		to_chat(owner, span_warning("You lack the necessary living force for this action."))
		return

	var/mob/living/living_owner = owner
	if (living_owner.usable_hands <= 0)
		to_chat(living_owner, span_warning("You don't have any usable hands!"))
	else
		to_chat(living_owner, span_warning("Your hands are full!"))
