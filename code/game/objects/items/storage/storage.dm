/obj/item/storage
	name = "storage"
	icon = 'icons/obj/storage/storage.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	attack_style = null
	var/rummage_if_nodrop = TRUE
	/// Should we preload the contents of this type?
	/// BE CAREFUL, THERE'S SOME REALLY NASTY SHIT IN THIS TYPEPATH
	/// SANTA IS EVIL
	var/preload = FALSE
	/// What storage type to use for this item
	var/datum/storage/storage_type = /datum/storage

/obj/item/storage/Initialize(mapload)
	. = ..()

	create_storage(storage_type = storage_type)

	PopulateContents()

	for (var/obj/item/item in src)
		item.item_flags |= IN_STORAGE

/obj/item/storage/create_storage(
	max_slots,
	max_specific_storage,
	max_total_storage,
	numerical_stacking,
	allow_quick_gather,
	allow_quick_empty,
	collection_mode,
	attack_hand_interact,
	list/canhold,
	list/canthold,
	storage_type,
	)
	if(!storage_type) // If no type was passed in, default to what we already have
		storage_type = src.storage_type
	return ..()


/obj/item/storage/AllowDrop()
	return FALSE

/obj/item/storage/contents_explosion(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += contents
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += contents
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += contents

/obj/item/storage/canStrip(mob/who)
	. = ..()
	if(!. && rummage_if_nodrop)
		return TRUE

/obj/item/storage/doStrip(mob/who)
	if(HAS_TRAIT(src, TRAIT_NODROP) && rummage_if_nodrop)
		atom_storage.remove_all()
		return TRUE
	return ..()

/obj/item/storage/contents_explosion(severity, target)
//Cyberboss says: "USE THIS TO FILL IT, NOT INITIALIZE OR NEW"

/obj/item/storage/proc/PopulateContents()

/obj/item/storage/proc/emptyStorage()
	atom_storage.remove_all()

/obj/item/storage/Destroy()
	for(var/obj/important_thing in contents)
		if(!(important_thing.resistance_flags & INDESTRUCTIBLE))
			continue
		important_thing.forceMove(drop_location())
	return ..()

/// Returns a list of object types to be preloaded by our code
/// I'll say it again, be very careful with this. We only need it for a few things
/// Don't do anything stupid, please
/obj/item/storage/proc/get_types_to_preload()
	return
