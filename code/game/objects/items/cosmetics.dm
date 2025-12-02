/obj/item/lipstick
	gender = PLURAL
	name = "red lipstick"
	desc = "A generic brand of lipstick."
	icon = 'icons/obj/cosmetic.dmi'
	icon_state = "lipstick"
	base_icon_state = "lipstick"
	inhand_icon_state = "lipstick"
	w_class = WEIGHT_CLASS_TINY
	interaction_flags_click = NEED_DEXTERITY|NEED_HANDS|ALLOW_RESTING
	var/open = FALSE
	/// Actual color of the lipstick, also gets applied to the human
	var/lipstick_color = COLOR_RED
	/// The style of lipstick. Upper, middle, or lower lip. Default is middle.
	var/style = "lipstick"
	/// A trait that's applied while someone has this lipstick applied, and is removed when the lipstick is removed
	var/lipstick_trait
	/// Can this lipstick spawn randomly
	var/random_spawn = TRUE

/obj/item/lipstick/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	update_appearance(UPDATE_ICON)

/obj/item/lipstick/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, open))
		update_appearance(UPDATE_ICON)

/obj/item/lipstick/examine(mob/user)
	. = ..()
	. += "Alt-click to change the style."

/obj/item/lipstick/update_icon_state()
	icon_state = "[base_icon_state][open ? "_uncap" : null]"
	inhand_icon_state = "[base_icon_state][open ? "open" : null]"
	return ..()

/obj/item/lipstick/update_overlays()
	. = ..()
	if(!open)
		return
	var/mutable_appearance/colored_overlay = mutable_appearance(icon, "lipstick_uncap_color")
	colored_overlay.color = lipstick_color
	. += colored_overlay

/obj/item/lipstick/click_alt(mob/user)
	display_radial_menu(user)
	return CLICK_ACTION_SUCCESS

/obj/item/lipstick/proc/display_radial_menu(mob/living/carbon/human/user)
	var/style_options = list(
		UPPER_LIP = icon('icons/hud/radial.dmi', UPPER_LIP),
		MIDDLE_LIP = icon('icons/hud/radial.dmi', MIDDLE_LIP),
		LOWER_LIP = icon('icons/hud/radial.dmi', LOWER_LIP),
	)
	var/pick = show_radial_menu(user, src, style_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE)
	if(!pick)
		return TRUE

	switch(pick)
		if(MIDDLE_LIP)
			style = "lipstick"
		if(LOWER_LIP)
			style = "lipstick_lower"
		if(UPPER_LIP)
			style = "lipstick_upper"
	return TRUE

/obj/item/lipstick/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated || !user.is_holding(src))
		return FALSE
	return TRUE

/obj/item/lipstick/purple
	name = "purple lipstick"
	lipstick_color = COLOR_PURPLE

/obj/item/lipstick/jade
	name = "jade lipstick"
	lipstick_color = COLOR_JADE

/obj/item/lipstick/blue
	name = "blue lipstick"
	lipstick_color = COLOR_BLUE

/obj/item/lipstick/green
	name = "green lipstick"
	lipstick_color = COLOR_GREEN

/obj/item/lipstick/white
	name = "white lipstick"
	lipstick_color = COLOR_WHITE

/obj/item/lipstick/black
	name = "black lipstick"
	lipstick_color = COLOR_BLACK

/obj/item/lipstick/black/death
	name = "\improper Kiss of Death"
	desc = "An incredibly potent tube of lipstick made from the venom of the dreaded Yellow Spotted Space Lizard, as deadly as it is chic. Try not to smear it!"
	lipstick_trait = TRAIT_KISS_OF_DEATH
	random_spawn = FALSE

/obj/item/lipstick/syndie
	name = "syndie lipstick"
	desc = "Syndicate branded lipstick with a killer dose of kisses. Observe safety regulations!"
	icon_state = "slipstick"
	base_icon_state = "slipstick"
	lipstick_color = COLOR_SYNDIE_RED
	lipstick_trait = TRAIT_SYNDIE_KISS
	random_spawn = FALSE

/obj/item/lipstick/random
	name = "lipstick"
	icon_state = "random_lipstick"

/obj/item/lipstick/random/Initialize(mapload)
	. = ..()
	icon_state = "lipstick"
	var/static/list/possible_colors
	if(!possible_colors)
		possible_colors = list()
		for(var/obj/item/lipstick/lipstick_path as anything in (typesof(/obj/item/lipstick) - src.type))
			if(!initial(lipstick_path.lipstick_color) || !initial(lipstick_path.random_spawn))
				continue
			possible_colors[initial(lipstick_path.lipstick_color)] = initial(lipstick_path.name)
	lipstick_color = pick(possible_colors)
	name = possible_colors[lipstick_color]
	update_appearance()

/obj/item/lipstick/attack_self(mob/user)
	to_chat(user, span_notice("You twist [src] [open ? "closed" : "open"]."))
	open = !open
	update_appearance(UPDATE_ICON)

/obj/item/lipstick/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!open || !ismob(interacting_with))
		return NONE

	if(!ishuman(interacting_with))
		to_chat(user, span_warning("Where are the lips on that?"))
		return ITEM_INTERACT_BLOCKING

	var/mob/living/carbon/human/target = interacting_with
	if(target.is_mouth_covered())
		to_chat(user, span_warning("Remove [ target == user ? "your" : "[target.p_their()]" ] mask!"))
		return ITEM_INTERACT_BLOCKING
	if(target.lip_style) //if they already have lipstick on
		to_chat(user, span_warning("You need to wipe off the old lipstick first!"))
		return ITEM_INTERACT_BLOCKING

	if(target == user)
		user.visible_message(
			span_notice("[user] does [user.p_their()] lips with [src]."),
			span_notice("You take a moment to apply [src]. Perfect!"),
		)
		target.update_lips(style, lipstick_color, lipstick_trait)
		return ITEM_INTERACT_SUCCESS

	user.visible_message(
		span_warning("[user] begins to do [target]'s lips with \the [src]."),
		span_notice("You begin to apply \the [src] on [target]'s lips..."),
	)
	if(!do_after(user, 2 SECONDS, target))
		return ITEM_INTERACT_BLOCKING
	user.visible_message(
		span_notice("[user] does [target]'s lips with \the [src]."),
		span_notice("You apply \the [src] on [target]'s lips."),
	)
	target.update_lips(style, lipstick_color, lipstick_trait)
	return ITEM_INTERACT_SUCCESS

//you can wipe off lipstick with paper!
/obj/item/paper/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(user.zone_selected != BODY_ZONE_PRECISE_MOUTH || !ishuman(interacting_with))
		return NONE

	var/mob/living/carbon/human/target = interacting_with
	if(!target.lip_style) //if they don't have lipstick on
		return NONE
	if(target.is_mouth_covered())
		to_chat(user, span_warning("Remove [ target == user ? "your" : "[target.p_their()]" ] mask!"))
		return ITEM_INTERACT_BLOCKING
	if(target == user)
		to_chat(user, span_notice("You wipe off the lipstick with [src]."))
		target.update_lips(null)
		return ITEM_INTERACT_SUCCESS

	user.visible_message(
		span_warning("[user] begins to wipe [target]'s lipstick off with [src]."),
		span_notice("You begin to wipe off [target]'s lipstick..."),
	)
	if(!do_after(user, 1 SECONDS, target = target))
		return ITEM_INTERACT_BLOCKING
	user.visible_message(
		span_notice("[user] wipes [target]'s lipstick off with [src]."),
		span_notice("You wipe off [target]'s lipstick."),
	)
	target.update_lips(null)
	return ITEM_INTERACT_SUCCESS

/obj/item/razor
	name = "electric razor"
	desc = "The latest and greatest power razor born from the science of shaving."
	icon = 'icons/obj/cosmetic.dmi'
	icon_state = "razor"
	inhand_icon_state = "razor"
	obj_flags = CONDUCTS_ELECTRICITY
	w_class = WEIGHT_CLASS_TINY
	sound_vary = TRUE
	pickup_sound = SFX_GENERIC_DEVICE_PICKUP
	drop_sound = SFX_GENERIC_DEVICE_DROP

/obj/item/razor/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/barber_item)

/obj/item/razor/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins shaving [user.p_them()]self without the razor guard! It looks like [user.p_theyre()] trying to commit suicide!"))
	user.set_facial_hairstyle("Shaved")
	user.set_hairstyle("Skinhead", update = TRUE)
	playsound(src, 'sound/items/tools/welder2.ogg', 20, TRUE)
	return BRUTELOSS

/obj/item/razor/surgery
	name = "surgical razor"
	desc = "A medical grade razor. Its precision blades provide a clean shave for surgical preparation."
	icon = 'icons/obj/cosmetic.dmi'
	icon_state = "medrazor"

/obj/item/razor/surgery/get_surgery_tool_overlay(tray_extended)
	return "razor"
