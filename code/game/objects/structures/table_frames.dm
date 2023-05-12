/* Table Frames
 * Contains:
 * Frames
 * Wooden Frames
 */


/*
 * Normal Frames
 */

/obj/structure/table_frame
	name = "table frame"
	desc = "Four metal legs with four framing rods for a table. You could easily pass through this."
	icon = 'icons/obj/structures.dmi'
	icon_state = "table_frame"
	density = FALSE
	anchored = FALSE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	max_integrity = 100
	var/framestack = /obj/item/stack/rods
	var/framestackamount = 2

/obj/structure/table_frame/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You start disassembling [src]..."))
	I.play_tool_sound(src)
	if(!I.use_tool(src, user, 3 SECONDS))
		return TRUE
	playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
	deconstruct(TRUE)
	return TRUE


/obj/structure/table_frame/attackby(obj/item/I, mob/user, params)
	if(isstack(I))
		try_add_sheet(I, user)
		return TRUE

	return ..()

/obj/structure/table_frame/proc/try_add_sheet(obj/item/stack/material, mob/user)
	if(!material.tableVariant && !istype(material, /obj/item/stack/sheet))
		return
	if(material.get_amount() < 1)
		to_chat(user, span_warning("You need one[material.tableVariant ? " [material.name] " : " "]sheet to do this!"))
		return
	if(locate(/obj/structure/table) in loc)
		to_chat(user, span_warning("There's already a table built here!"))
		return

	to_chat(user, span_notice("You start adding [material] to [src]..."))
	if(!do_after(user, 2 SECONDS, target = src) || !material.use(1) || (locate(/obj/structure/table) in loc))
		return

	add_sheet(material, user)

/obj/structure/table_frame/proc/add_sheet(obj/item/stack/material, mob/user)
	if(material.tableVariant)
		make_new_table(material.tableVariant)

	else
		var/list/material_list = list()
		if(material.material_type)
			material_list[material.material_type] = SHEET_MATERIAL_AMOUNT
		make_new_table(/obj/structure/table/greyscale, material_list)

/obj/structure/table_frame/proc/make_new_table(table_type, custom_materials, carpet_type) //makes sure the new table made retains what we had as a frame
	var/obj/structure/table/T = new table_type(loc)
	T.frame = type
	T.framestack = framestack
	T.framestackamount = framestackamount
	if (carpet_type)
		T.buildstack = carpet_type
	if(custom_materials)
		T.set_custom_materials(custom_materials)
	qdel(src)

/obj/structure/table_frame/deconstruct(disassembled = TRUE)
	new framestack(get_turf(src), framestackamount)
	qdel(src)

/obj/structure/table_frame/narsie_act()
	new /obj/structure/table_frame/wood(loc)
	qdel(src)

/*
 * Wooden Frames
 */

/obj/structure/table_frame/wood
	name = "wooden table frame"
	desc = "Four wooden legs with four framing wooden rods for a wooden table. You could easily pass through this."
	icon_state = "wood_frame"
	framestack = /obj/item/stack/sheet/mineral/wood
	framestackamount = 2
	resistance_flags = FLAMMABLE

/obj/structure/table_frame/wood/try_add_sheet(obj/item/stack/material, mob/user)
	if(!istype(material, /obj/item/stack/sheet/mineral/wood) && !istype(material, /obj/item/stack/tile/carpet))
		to_chat(user, span_warning("[material] doesn't fit on [src]."))
		return

	return ..()

/obj/structure/table_frame/wood/add_sheet(obj/item/stack/material, mob/user)
	if(istype(material, /obj/item/stack/tile/carpet))
		make_new_table(/obj/structure/table/wood/poker, null, material.type)
		return

	// Will not get called typically
	return ..()

/obj/structure/table_frame/wood/narsie_act()
	return
