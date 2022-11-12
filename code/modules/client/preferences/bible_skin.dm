/datum/preference/choiced/bible_skin
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "preferred_bible_skin"
	should_generate_icons = TRUE

/datum/preference/choiced/bible_skin/init_possible_values()
	var/list/values = list()

	values[DEFAULT_BIBLE_SKIN] = create_bible_icon('icons/obj/bibles.dmi', "bible")

	for(var/skin_name in GLOB.bible_names_to_skins)
		var/datum/bible_skin/skin = GLOB.bible_names_to_skins[skin_name]
		values[skin_name] = create_bible_icon(skin.bible_icon, skin.bible_icon_state)

	return values

/datum/preference/choiced/bible_skin/create_default_value()
	return DEFAULT_BIBLE_SKIN

/datum/preference/choiced/bible_skin/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return istype(preferences.get_highest_priority_job(), /datum/job/chaplain)

/datum/preference/choiced/bible_skin/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/choiced/bible_skin/proc/create_bible_icon(icon_file, icon_state)
	var/icon/new_icon = icon(icon_file, icon_state)
	new_icon.Scale(96, 96) // melbert todo don't work
	return new_icon
