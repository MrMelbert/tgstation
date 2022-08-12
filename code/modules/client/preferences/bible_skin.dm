/datum/preference/choiced/bible_skin
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "preferred_bible_skin"
	should_generate_icons = TRUE

/datum/preference/choiced/bible_skin/init_possible_values()
	var/list/values = list()

	values[DEFAULT_BIBLE_SKIN] = image(icon = 'icons/obj/bibles.dmi', icon_state = "bible")

	for(var/datum/bible_skin/skin as anything in GLOB.bible_skins_to_images)
		values[skin.name] = GLOB.bible_skins_to_images[skin]

	return values

/datum/preference/choiced/bible_skin/create_default_value()
	return DEFAULT_BIBLE_SKIN

/datum/preference/choiced/bible_skin/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return istype(preferences.get_highest_priority_job(), /datum/job/chaplain)

/datum/preference/choiced/bible_skin/apply_to_human(mob/living/carbon/human/target, value)
	return
