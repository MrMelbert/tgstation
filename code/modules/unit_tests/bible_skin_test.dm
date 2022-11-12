/**
 * Valides all bible skin setups.
 */
/datum/unit_test/bible_skins

/datum/unit_test/bible_skins/Run()
	for(var/skin_name in GLOB.bible_names_to_skins)
		var/datum/bible_skin/skin = GLOB.bible_names_to_skins[skin_name]
		if(!skin.bible_icon)
			Fail("Bible skin [skin_name] ([skin.type]) didn't have an icon set!")
		if(!skin.bible_icon_state)
			Fail("Bible skin [skin_name] ([skin.type]) didn't have an icon state set!")
		else if(!icon_exists(skin.bible_icon, skin.bible_icon_state))
			Fail("Bible skin [skin_name] ([skin.type])'s icon state was not found in its icon file!")

		if(!skin.bible_righthand_icon)
			Fail("Bible skin [skin_name] ([skin.type]) didn't have an righthand file set!")
		if(!skin.bible_lefthand_icon)
			Fail("Bible skin [skin_name] ([skin.type]) didn't have an lefthand file set!")
		if(!skin.bible_inhand_icon_state)
			Fail("Bible skin [skin_name] ([skin.type]) didn't have an inhand icon state set!")
		else
			if(!icon_exists(skin.bible_righthand_icon, skin.bible_inhand_icon_state))
				Fail("Bible skin [skin_name] ([skin.type])'s inhand icon state was not found in its right hand icon file!")
			if(!icon_exists(skin.bible_lefthand_icon, skin.bible_inhand_icon_state))
				Fail("Bible skin [skin_name] ([skin.type])'s inhand icon state was not found in its left hand icon file!")
