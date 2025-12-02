/datum/element/barber_item

/datum/element/barber_item/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(on_interaction))

/datum/element/barber_item/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_ITEM_INTERACTING_WITH_ATOM)

/datum/element/barber_item/proc/on_interaction(datum/source, atom/interacting_with, mob/living/user, list/modifiers)
	SIGNAL_HANDLER

	if(!ishuman(interacting_with))
		return NONE

	if(deprecise_zone(user.zone_selected) != BODY_ZONE_HEAD)
		return NONE

	var/mob/living/carbon/human/human_target = interacting_with
	if(isnull(human_target.get_bodypart(BODY_ZONE_HEAD)))
		to_chat(user, span_warning("[human_target] has no hair of any kind to style!"))
		return ITEM_INTERACT_BLOCKING

	INVOKE_ASYNC(src, PROC_REF(handle_haircut), interacting_with, user, source)
	return ITEM_INTERACT_BLOCKING

/datum/element/barber_item/proc/handle_haircut(mob/living/carbon/human/human_target, mob/living/user, obj/item/tool)
	if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		facial_hair_shave(human_target, user, tool, user.combat_mode ? /datum/sprite_accessory/facial_hair/shaved::name : null)
	else
		head_hair_shave(human_target, user, tool, user.combat_mode ? /datum/sprite_accessory/hair/skinhead::name : null)

/datum/element/barber_item/proc/facial_hair_shave(mob/living/carbon/human/human_target, mob/living/user, obj/item/tool, forced_style)
	if(human_target == user && !forced_style)
		var/obj/structure/mirror/mirror = locate() in view(2, user)
		if(isnull(mirror))
			to_chat(user, span_warning("You need a mirror to properly style your own facial hair!"))
			return

	if(!can_facial_shave(human_target, user, tool))
		return
	var/new_style = forced_style || tgui_input_list(user, "Select a facial hairstyle", "Grooming", SSaccessories.facial_hairstyles_list)
	if(isnull(new_style) || !can_facial_shave(human_target, user, tool))
		return
	var/is_shave = new_style == /datum/sprite_accessory/facial_hair/shaved::name
	user.visible_message(
		span_notice("[user] tries to [is_shave ? "shave" : "change"] [human_target == user ? user.p_their() : "[human_target]'s"] facial hair using [tool]."),
		span_notice("You try to [is_shave ? "shave" : "change"] [human_target == user ? "your" : "[human_target]'s"] facial hair using [tool]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	playsound(src, 'sound/items/hair-clippers.ogg', 50)
	if(!do_after(user, 6 SECONDS, human_target, extra_checks = CALLBACK(src, PROC_REF(can_facial_shave), human_target, user, tool)))
		return
	if(is_shave)
		playsound(tool, 'sound/items/tools/welder2.ogg', 20, TRUE)
	user.visible_message(
		span_notice("[user] successfully [is_shave ? "shaves" : "changes"] [human_target == user ? user.p_their() : "[human_target]'s"] facial hair using [tool]."),
		span_notice("You successfully [is_shave ? "shave" : "change"] [human_target == user ? user.p_their() : "[human_target]'s"] facial hair using [tool]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	human_target.set_facial_hairstyle(new_style, update = TRUE)

/datum/element/barber_item/proc/can_facial_shave(mob/living/carbon/human/human_target, mob/living/user, obj/item/tool)
	if(human_target.gender != MALE)
		return FALSE
	if(!user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return FALSE
	if(!user.is_holding(tool))
		return FALSE
	if(!get_location_accessible(human_target, BODY_ZONE_PRECISE_MOUTH))
		to_chat(user, span_warning("You can't reach [human_target]'s facial hair!"))
		return FALSE
	var/obj/item/bodypart/head/noggin = human_target.get_bodypart(BODY_ZONE_HEAD)
	if(isnull(noggin) || !(noggin.head_flags & HEAD_FACIAL_HAIR))
		to_chat(user, span_warning("There is no facial hair to style!"))
		return FALSE
	if(HAS_TRAIT(human_target, TRAIT_SHAVED))
		to_chat(user, span_warning("[human_target] is just way too shaved. Like, really really shaved."))
		return FALSE
	return TRUE

/datum/element/barber_item/proc/head_hair_shave(mob/living/carbon/human/human_target, mob/living/user, obj/item/tool, forced_style)
	if(human_target == user && !forced_style)
		var/obj/structure/mirror/mirror = locate() in view(2, user)
		if(isnull(mirror))
			to_chat(user, span_warning("You need a mirror to properly style your own head!"))
			return

	if(!can_head_shave(human_target, user, tool))
		return
	var/new_style = forced_style || tgui_input_list(user, "Select a hairstyle", "Grooming", SSaccessories.hairstyles_list)
	if(isnull(new_style) || !can_head_shave(human_target, user, tool))
		return
	var/is_shave = new_style == /datum/sprite_accessory/hair/skinhead::name \
		|| new_style == /datum/sprite_accessory/hair/bald::name \
		|| new_style == /datum/sprite_accessory/hair/shaved::name
	user.visible_message(
		span_notice("[user] tries to [is_shave ? "shave" : "change"] [human_target == user ? user.p_their() : "[human_target]'s"] hair using [tool]."),
		span_notice("You try to [is_shave ? "shave" : "change"] [human_target == user ? "your" : "[human_target]'s"] hair using [tool]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	playsound(tool, 'sound/items/hair-clippers.ogg', 50)
	if(!do_after(user, 6 SECONDS, human_target, extra_checks = CALLBACK(src, PROC_REF(can_head_shave), human_target, user, tool)))
		return
	if(is_shave)
		playsound(tool, 'sound/items/tools/welder2.ogg', 20, TRUE)
	user.visible_message(
		span_notice("[user] successfully [is_shave ? "shaves" : "changes"] [human_target == user ? user.p_their() : "[human_target]'s"] hair using [tool]."),
		span_notice("You successfully [is_shave ? "shave" : "change"] [human_target == user ? p_their() : "[human_target]'s"] hair using [tool]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)
	human_target.set_hairstyle(new_style, update = TRUE)

/datum/element/barber_item/proc/can_head_shave(mob/living/carbon/human/human_target, mob/living/user, obj/item/tool)
	if(!user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return FALSE
	if(!user.is_holding(tool))
		return FALSE
	if(!get_location_accessible(human_target, BODY_ZONE_HEAD))
		to_chat(user, span_warning("You can't reach [human_target]'s hair!"))
		return FALSE
	var/obj/item/bodypart/head/noggin = human_target.get_bodypart(BODY_ZONE_HEAD)
	if(isnull(noggin) || !(noggin.head_flags & HEAD_HAIR))
		to_chat(user, span_warning("There is no hair to style!"))
		return FALSE
	if(HAS_TRAIT(human_target, TRAIT_BALD))
		to_chat(user, span_warning("[human_target] is just way too bald. Like, really really bald."))
		return FALSE
	return TRUE
