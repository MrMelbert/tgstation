/datum/quirk/anti_signer
	name = "Sign Deaf"
	desc = "You can't comprehend all forms of sign language, including Galactic Sign Language."
	icon = FA_ICON_HANDS_BOUND
	value = 0
	medical_record_text = "Patient failed sensitivity training, and is unable to comprehend Galactic Sign Language."

/datum/quirk/anti_signer/add(client/client_source)
	quirk_holder.add_blocked_language(valid_typesof(/datum/language/sign_language), ALL, LANGUAGE_QUIRK)
	quirk_holder.get_language_holder().selected_language = /datum/language/sign_language/common

/datum/quirk/anti_signer/remove()
	quirk_holder.remove_blocked_language(valid_typesof(/datum/language/sign_language), ALL, LANGUAGE_QUIRK)
