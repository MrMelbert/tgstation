///Proxy element that attaches components, elements and traits that are common to more or less all nullrods.
/datum/element/nullrod_core

/**
 * Called when the element is added to a datum. If the 'chaplain_spawnable' arg is TRUE and unit testing is enabled,
 * we check that the target is actually in the nullrod_variants global list
 */
/datum/element/nullrod_core/Attach(obj/item/target, chaplain_spawnable = TRUE, rune_remove_line = "BEGONE FOUL MAGIKS!!")
	. = ..()
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE

	// the handle of a nullrod is always obsidian - the rest of the materials and slots, if present, are inherited
	var/list/applied_materials = list(/datum/material/obsidian = 4 * SHEET_MATERIAL_AMOUNT)
	for(var/datum/material/existing_material, existing_material_amount in target.custom_materials)
		if(existing_material.type == /datum/material/obsidian)
			continue
		applied_materials[existing_material.type] = existing_material_amount

	var/list/applied_slots = list(/datum/material_slot/handle = /datum/material/obsidian)
	for(var/existing_slot, existing_slot_material in target.material_slots)
		if(existing_slot == /datum/material_slot/handle)
			// if it already has a handle, obsidian takes on its volume and replaces it - so iron handle becomes obsidian handle
			applied_materials[/datum/material/obsidian] = applied_materials[existing_slot_material] || SHEET_MATERIAL_AMOUNT
			applied_materials -= existing_slot_material
			continue
		applied_slots[existing_slot] = existing_slot_material

	target.material_flags |= MATERIAL_EFFECTS
	target.set_custom_materials(applied_materials)
	target.set_material_slots(applied_slots)

	target.AddComponent(/datum/component/effect_remover, \
		success_feedback = "You disrupt the magic of %THEEFFECT with %THEWEAPON.", \
		success_forcesay = rune_remove_line, \
		tip_text = "Clear rune", \
		on_clear_callback = CALLBACK(src, PROC_REF(on_cult_rune_removed), target), \
		effects_we_clear = list(/obj/effect/rune, /obj/effect/heretic_rune, /obj/effect/cosmic_rune), \
	)
	target.AddComponent(/datum/component/cult_kill_tracker)
	target.AddComponent(/datum/component/bane, affected_biotypes = MOB_SPIRIT, added_damage = 25)
	ADD_TRAIT(target, TRAIT_NULLROD_ITEM, ELEMENT_TRAIT(type))

	if(!PERFORM_ALL_TESTS(focus_only/nullrod_variants) || !chaplain_spawnable)
		return

	if(!GLOB.nullrod_variants[target.type])
		stack_trace("[target.type] is absent from the nullrod_variants global list. Please include it.")

/// Callback for effect remover, invoked when a cult rune is cleared
/datum/element/nullrod_core/proc/on_cult_rune_removed(obj/item/nullrod, obj/effect/target, mob/living/user)
	if(!istype(target, /obj/effect/rune))
		return

	var/obj/effect/rune/target_rune = target
	if(target_rune.log_when_erased)
		user.log_message("erased [target_rune.cultist_name] rune using [nullrod]", LOG_GAME)
	SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_NARNAR] = TRUE
