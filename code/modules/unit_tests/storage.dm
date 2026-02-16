/// Test storage datums
/datum/unit_test/storage

/datum/unit_test/storage/Run()
	var/obj/item/big_thing = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	big_thing.w_class = WEIGHT_CLASS_BULKY
	var/obj/item/small_thing =  allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	small_thing.w_class = WEIGHT_CLASS_SMALL

	var/obj/item/storage/backpack/storage_item =  allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)

	storage_item.atom_storage.attempt_insert(big_thing)
	TEST_ASSERT_NOTEQUAL(big_thing.loc, storage_item, "A bulky item should have failed to insert into a backpack")

	storage_item.atom_storage.attempt_insert(small_thing)
	TEST_ASSERT_EQUAL(small_thing.loc, storage_item, "A small item should have successfully inserted into a backpack")

	small_thing.update_weight_class(WEIGHT_CLASS_NORMAL)
	TEST_ASSERT_EQUAL(small_thing.loc, storage_item, "A small item changed into normal size should not have ejected from the backpack")

	small_thing.update_weight_class(WEIGHT_CLASS_BULKY)
	TEST_ASSERT_NOTEQUAL(small_thing.loc, storage_item, "A small item changed back into bulky size should have ejected from the backpack")

/datum/unit_test/common_item_inserting

/datum/unit_test/common_item_inserting/Run()
	var/obj/item/storage/backpack/bag = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/consistent/dummy = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	bag.atom_storage.max_slots = INFINITY
	bag.atom_storage.max_total_storage = INFINITY

	var/list/common_noncombat_insertion_items = list(
		/obj/item/rag,
		/obj/item/soap,
		/obj/item/card/emag,
		/obj/item/detective_scanner,
	)

	dummy.set_combat_mode(TRUE)
	for(var/item_type in common_noncombat_insertion_items)
		var/obj/item/item = allocate(item_type, run_loc_floor_bottom_left)
		item.melee_attack_chain(dummy, bag)
		TEST_ASSERT_EQUAL(item.loc, bag, "[item_type] was unable to be inserted into a backpack on click while off combat mode")

/datum/unit_test/initial_storage

/datum/unit_test/initial_storage/Run()
	for(var/storage_item in subtypesof(/obj/item/storage))
		if(findtext("[storage_item]", "directional"))
			continue
		var/obj/item/storage/created = allocate(storage_item)
		if(QDELETED(created))
			continue // INITIALIZE_HINT_QDEL
		var/list/reported_holdables = list()
		var/list/reported_unholdables = list()
		for(var/obj/item/thing in created)
			if(!(thing.type in reported_holdables) && !check_is_holdable(created, thing))
				reported_holdables += thing.type
			if(!(thing.type in reported_unholdables) && !check_is_not_holdable(created, thing))
				reported_unholdables += thing.type

/datum/unit_test/initial_storage/proc/check_is_holdable(obj/item/storage, obj/item/thing)
	if(!length(storage.atom_storage.can_hold))
		return TRUE
	if(is_type_in_typecache(thing, storage.atom_storage.can_hold))
		return TRUE
	if(is_type_in_typecache(thing, storage.atom_storage.exception_hold))
		return TRUE
	TEST_FAIL("[thing.type] is pre-stocked in [storage.type] but is not in its can_hold list!")
	return FALSE

/datum/unit_test/initial_storage/proc/check_is_not_holdable(obj/item/storage, obj/item/thing)
	if(!length(storage.atom_storage.cant_hold))
		return TRUE
	if(!is_type_in_typecache(thing, storage.atom_storage.cant_hold))
		return TRUE
	TEST_FAIL("[thing.type] is pre-stocked in [storage.type] but is not in its cant_hold list!")
	return FALSE
