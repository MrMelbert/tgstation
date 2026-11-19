/datum/language/galactic_sign
	name = "Galactic Sign Language"
	desc = "A universal sign language used for non-verbal communication across the galaxy."
	flags = LANGUAGE_HIDE_ICON_IF_UNDERSTOOD | LANGUAGE_VISUAL
	/// Any symbols to sanitize from signed messages.
	var/static/regex/omissions = new ("\[!?\]", "g")

/datum/language/galactic_sign/modify_message(message)
	if(get_unfilled_hands(carbon_parent) == 1)
		message = stars(message)

	if(HAS_TRAIT_FROM_ONLY(carbon_parent, TRAIT_RESTRAINED, HANDCUFFED_TRAIT))
		message = stifled(message)

	return replacetext(message, omissions, ".")

/datum/language/galactic_sign/scramble_paragraph(input, list/mutual_languages)
	if(length(mutual_languages))
		return ..()
	return "makes an unknown gesture"

/datum/language/galactic_sign/scramble_word(input)
	return ".."

/datum/language/galactic_sign/can_atom_speak_language(atom/movable/some_atom, feedback)
	return TRUE

/datum/language/galactic_sign/can_atom_speak(atom/movable/some_atom, allow_mimes, feedback)
	if(!iscarbon(some_atom))
		return TRUE

	var/mob/living/carbon/carbon_parent = some_atom
	if(HAS_MIND_TRAIT(carbon_parent, TRAIT_MIMING))
		if(feedback)
			to_chat(carbon_parent, span_green("You stop yourself from signing in favor of the artform of mimery!"))
		return FALSE

	if(carbon_parent.usable_hands <= 0)
		if(carbon_parent.num_hands > 0)
			if(feedback)
				to_chat(carbon_parent, span_warning("You can't sign with your hands right now!"))
		else
			if(feedback)
				to_chat(carbon_parent, span_warning("You can't sign with no hands!"))

		return FALSE

	if(HAS_TRAIT(carbon_parent, TRAIT_RESTRAINED))
		if(HAS_TRAIT_FROM_ONLY(carbon_parent, TRAIT_RESTRAINED, HANDCUFFED_TRAIT))
			if(feedback)
				carbon_parent.visible_message("struggles, signing slowly with [carbon_parent.p_their()] hands cuffed...", visible_message_flags = EMOTE_MESSAGE)
			return TRUE // allowed, but elsewhere we mess with it
		if(feedback)
			carbon_parent.visible_message("tries to sign, but can't with [carbon_parent.p_their()] hands bound!", visible_message_flags = EMOTE_MESSAGE)
		return FALSE

	if(HAS_TRAIT(carbon_parent, TRAIT_HANDS_BLOCKED) || HAS_TRAIT(carbon_parent, TRAIT_EMOTEMUTE))
		if(feedback)
			to_chat(carbon_parent, span_warning("You can't sign at the moment!"))
		return FALSE

	if(get_unfilled_hands(carbon_parent) <= 0)
		if(feedback)
			carbon_parent.visible_message("tries to sign, but can't with [carbon_parent.p_their()] hands full!", visible_message_flags = EMOTE_MESSAGE)
		return FALSE

	return TRUE

/datum/language/galactic_sign/proc/get_unfilled_hands(mob/living/carbon/carbon_parent)
	var/hands = carbon_parent.usable_hands
	for(var/obj/item/held_item as anything in carbon_parent.get_held_items())
		// items like slappers/zombie claws/etc. should be ignored
		if(held_item.item_flags & HAND_ITEM)
			continue

		hands -= 1

	return hands
