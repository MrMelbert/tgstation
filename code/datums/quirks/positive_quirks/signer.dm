/datum/quirk/item_quirk/signer
	name = "Signer"
	desc = "You possess communication skills in Galactic Sign Language, and possibly even a sign language native to your culture."
	icon = FA_ICON_HANDS
	value = 4
	quirk_flags = QUIRK_HUMAN_ONLY|QUIRK_CHANGES_APPEARANCE
	medical_record_text = "Patient can communicate with sign language."
	mail_goodies = list(/obj/item/clothing/gloves/radio)

/datum/quirk/item_quirk/signer/add(client/client_source)
	quirk_holder.grant_language(/datum/language/sign_language/common, ALL, LANGUAGE_QUIRK)
	if(islizard(quirk_holder))
		quirk_holder.grant_language(/datum/language/sign_language/lizard, ALL, LANGUAGE_QUIRK)
	if(ismoth(quirk_holder))
		quirk_holder.grant_language(/datum/language/sign_language/moth, ALL, LANGUAGE_QUIRK)

/datum/quirk/item_quirk/signer/add_unique(client/client_source)
	var/obj/item/clothing/gloves/gloves_type = /obj/item/clothing/gloves/radio
	if(isplasmaman(quirk_holder))
		gloves_type = /obj/item/clothing/gloves/color/plasmaman/radio
	give_item_to_holder(gloves_type, list(LOCATION_GLOVES, LOCATION_HANDS))

/datum/quirk/item_quirk/signer/remove()
	for(var/language_type in valid_typesof(/datum/language/sign_language))
		quirk_holder.remove_language(language_type, ALL, LANGUAGE_QUIRK)
