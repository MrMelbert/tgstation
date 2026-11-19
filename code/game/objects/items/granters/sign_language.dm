/// Sign language book adds the sign language component to the reading Human.
/// Grants reader the ability to toggle sign language using a HUD button.
/obj/item/book/granter/sign_language
	name = "Galactic Standard Sign Language"
	desc = "A comprehensive guide to learning sign language and finger-spelling."
	remarks = list(
		"Signing comprises a range of techniques...",
		"Words can be spelled out through sequences of signs...",
		"The way your palm faces?",
		"With questions, the eyebrows are lowered...",
		"Cool! Extensive coverage of common phrases!",
		"Communicate just about anything through signing...",
	)

/obj/item/book/granter/sign_language/can_learn(mob/living/user)
	if (user.has_language(/datum/language/sign_language/common, ALL, LANGUAGE_MIND))
		to_chat(user, span_warning("You already know all about sign language!"))
		return FALSE
	if(user.has_quirk(/datum/quirk/anti_signer))
		to_chat(user, span_warning("You struggle to understand the symbology presented before you."))
		return FALSE
	return TRUE

/obj/item/book/granter/sign_language/recoil(mob/living/user)
	to_chat(user, span_warning("You can't read it, the pages are too faded and smudged!"))

/// Called when the reading is completely finished. This is where the actual granting should happen.
/obj/item/book/granter/sign_language/on_reading_finished(mob/living/user)
	..()
	user.grant_language(/datum/language/sign_language/common, ALL, LANGUAGE_MIND)
