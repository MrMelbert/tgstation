/datum/hud/human
	default_inventory_slots = /datum/inventory_slot/human

/datum/hud/human/initialize_screen_objects()
	. = ..()
	var/atom/movable/screen/using
	// Static elements
	add_screen_object(/atom/movable/screen/language_menu, HUD_MOB_LANGUAGE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_language)
	add_screen_object(/atom/movable/screen/navigate, HUD_MOB_NAVIGATE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_navigate)
	add_screen_object(/atom/movable/screen/area_creator, HUD_MOB_AREA_CREATOR, HUD_GROUP_STATIC, ui_style, ui_human_area)
	add_screen_object(/atom/movable/screen/combattoggle/flashy, HUD_MOB_INTENTS, HUD_GROUP_INFO, ui_style)
	add_screen_object(/atom/movable/screen/floor_changer/vertical, HUD_MOB_FLOOR_CHANGER, HUD_GROUP_STATIC, ui_style, ui_human_floor_changer)
	add_screen_object(/atom/movable/screen/mov_intent, HUD_MOB_MOVE_INTENT, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/drop, HUD_MOB_DROP, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 1))
	add_screen_object(/atom/movable/screen/human/toggle, HUD_HUMAN_TOGGLE_INVENTORY, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/rest, HUD_MOB_REST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/sleep, HUD_MOB_SLEEP, HUD_GROUP_HOTKEYS, ui_style, ui_above_throw)
	add_screen_object(/atom/movable/screen/pull, HUD_MOB_PULL, HUD_GROUP_STATIC, ui_style, ui_above_movement_top)
	add_screen_object(/atom/movable/screen/zone_sel, HUD_MOB_ZONE_SELECTOR, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/memories, HUD_MOB_MEMORIES, HUD_GROUP_STATIC, ui_style, ui_human_memories_menu)
	build_hand_slots()

	using = add_screen_object(/atom/movable/screen/swap_hand, HUD_MOB_SWAPHAND_2, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 2))
	using.icon_state = "act_swap"

	// Hotkey buttons
	add_screen_object(/atom/movable/screen/resist, HUD_MOB_RESIST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/throw_catch, HUD_MOB_THROW, HUD_GROUP_HOTKEYS, ui_style)

	// Info
	add_screen_object(/atom/movable/screen/spacesuit, HUD_MOB_SPACESUIT, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healthdoll/human, HUD_MOB_HEALTHDOLL, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/stamina, HUD_MOB_STAMINA, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healths, HUD_MOB_HEALTH, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/hunger, HUD_MOB_HUNGER, HUD_GROUP_INFO)

/datum/hud/human/update_locked_slots()
	if(!ishuman(mymob))
		return

	var/mob/living/carbon/human/myhuman = mymob
	for(var/slot_key in screen_objects)
		var/atom/movable/screen/inventory/inv = screen_objects[slot_key]
		if(!istype(inv) || !inv.slot_id)
			continue

		inv.alpha = myhuman.can_equip_to_slot(inv.slot_id, disable_warning = TRUE) ? initial(inv.alpha) : 128

GAME_VERB_DESC(/mob/living/carbon/human, toggle_hotkey_verbs, "Toggle hotkey buttons", "This disables or enables the user interface buttons which can be used with hotkeys.", "OOC")

	if(hud_used.hotkey_ui_hidden)
		client.screen += hud_used.screen_groups[HUD_GROUP_HOTKEYS]
		hud_used.hotkey_ui_hidden = FALSE
	else
		client.screen -= hud_used.screen_groups[HUD_GROUP_HOTKEYS]
		hud_used.hotkey_ui_hidden = TRUE

/datum/inventory_slot/human
	abstract_type = /datum/inventory_slot/human

/datum/inventory_slot/human/uniform
	name = "uniform"
	slot_id = ITEM_SLOT_ICLOTHING
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = ui_iclothing
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/suit
	name = "suit"
	slot_id = ITEM_SLOT_OCLOTHING
	icon_state = "suit"
	icon_full = "template"
	screen_loc = ui_oclothing
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/id
	name = "id"
	icon_state = "id"
	icon_full = "template_small"
	screen_loc = ui_id
	slot_id = ITEM_SLOT_ID

/datum/inventory_slot/human/mask
	name = "mask"
	icon_state = "mask"
	icon_full = "template"
	screen_loc = ui_mask
	slot_id = ITEM_SLOT_MASK
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/neck
	name = "neck"
	icon_state = "neck"
	icon_full = "template"
	screen_loc = ui_neck
	slot_id = ITEM_SLOT_NECK
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/back
	name = "back"
	icon_state = "back"
	icon_full = "template_small"
	screen_loc = ui_back
	slot_id = ITEM_SLOT_BACK

/datum/inventory_slot/human/l_pocket
	name = "left pocket"
	icon_state = "pocket"
	icon_full = "template_small"
	screen_loc = ui_storage1
	slot_id = ITEM_SLOT_LPOCKET

/datum/inventory_slot/human/r_pocket
	name = "right pocket"
	icon_state = "pocket"
	icon_full = "template_small"
	screen_loc = ui_storage2
	slot_id = ITEM_SLOT_RPOCKET

/datum/inventory_slot/human/suit_storage
	name = "suit storage"
	icon_state = "suit_storage"
	icon_full = "template"
	screen_loc = ui_sstore1
	slot_id = ITEM_SLOT_SUITSTORE

/datum/inventory_slot/human/gloves
	name = "gloves"
	icon_state = "gloves"
	icon_full = "template"
	screen_loc = ui_gloves
	slot_id = ITEM_SLOT_GLOVES
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/eyes
	name = "eyes"
	icon_state = "glasses"
	icon_full = "template"
	screen_loc = ui_glasses
	slot_id = ITEM_SLOT_EYES
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/ears
	name = "ears"
	icon_state = "ears"
	icon_full = "template"
	screen_loc = ui_ears
	slot_id = ITEM_SLOT_EARS
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/head
	name = "head"
	icon_state = "head"
	icon_full = "template"
	screen_loc = ui_head
	slot_id = ITEM_SLOT_HEAD
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/shoes
	name = "shoes"
	icon_state = "shoes"
	icon_full = "template"
	screen_loc = ui_shoes
	slot_id = ITEM_SLOT_FEET
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/belt
	name = "belt"
	icon_state = "belt"
	icon_full = "template_small"
	screen_loc = ui_belt
	slot_id = ITEM_SLOT_BELT
