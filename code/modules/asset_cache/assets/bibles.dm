/datum/asset/spritesheet/bibles
	name = "bibles"

/datum/asset/spritesheet/bibles/create_spritesheets()
	for(var/skin_name in GLOB.bible_names_to_skins)
		var/datum/bible_skin/skin = GLOB.bible_names_to_skins[skin_name]
		Insert(skin_name, skin.bible_icon, skin.bible_icon_state)

/datum/asset/spritesheet/bibles/ModifyInserted(icon/pre_asset)
	pre_asset.Scale(224, 224) // Scale up by 7x
	return pre_asset
