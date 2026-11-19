/datum/language/sign_language
	abstract_type = /datum/language/sign_language
	flags = LANGUAGE_HIDE_ICON_IF_UNDERSTOOD | LANGUAGE_VISUAL
	/// Any symbols to sanitize from signed messages.
	var/static/regex/omissions = new ("\[!?\]", "g")
	/// Other sign languages intrinsically know about how each other works, to a degree
	var/mutual_sign_language_understanding = 80

/datum/language/sign_language/New()
	. = ..()
	for(var/sign_language_type in valid_typesof(/datum/language/sign_language))
		if(sign_language_type != type)
			mutual_understanding[sign_language_type] = mutual_sign_language_understanding

// Defines to determine the tone of the signer's message.
#define TONE_NEUTRAL 0 //! a statement
#define TONE_INQUISITIVE 1 //! a question
#define TONE_EMPHATIC 2 //! an exclamation
#define TONE_INQUISITIVE_EMPHATIC 3 //! both a question and an exclamation (interrobang)

/datum/language/sign_language/modify_message(mob/living/speaker, message)
	speaker.bubble_icon = "signlang" // melbert todo..

	var/exclamation_found = findtext(message, "!")
	var/question_found = findtext(message, "?")

	var/emote_tone = TONE_NEUTRAL
	if (exclamation_found && question_found)
		emote_tone = TONE_INQUISITIVE_EMPHATIC
	else if (exclamation_found)
		emote_tone = TONE_EMPHATIC
	else if (question_found)
		emote_tone = TONE_INQUISITIVE

	speaker.apply_status_effect(/datum/status_effect/tonal_indicator, emote_tone)
	if(HAS_TRAIT_FROM_ONLY(speaker, TRAIT_RESTRAINED, HANDCUFFED_TRAIT))
		speaker.visible_message("struggles, signing slowly with [speaker.p_their()] hands cuffed...", visible_message_flags = EMOTE_MESSAGE)
		message = stifled(message)

	else if(astype(speaker, /mob/living/carbon/human)?.is_face_obscured())
		pass()

	else
		switch(emote_tone)
			if(TONE_INQUISITIVE)
				speaker.visible_message(span_bold("quirks [speaker.p_their()] brows quizzically."), visible_message_flags = EMOTE_MESSAGE|BLOCK_SELF_HIGHLIGHT_MESSAGE)
			if(TONE_EMPHATIC)
				speaker.visible_message(span_bold("widens [speaker.p_their()] eyes emphatically!"), visible_message_flags = EMOTE_MESSAGE|BLOCK_SELF_HIGHLIGHT_MESSAGE)
			if(TONE_INQUISITIVE_EMPHATIC)
				speaker.visible_message(span_bold("wears an intense, befuddled expression!"), visible_message_flags = EMOTE_MESSAGE|BLOCK_SELF_HIGHLIGHT_MESSAGE)

	if(get_unfilled_hands(speaker) == 1)
		message = stars(message)

	// remove ! and ? symbols from message at the end
	message = replacetext(message, omissions, ".")

	return message

/datum/language/sign_language/add_saymods(datum/saymod_selector/selector)
	selector.add_saymod(SAY_MOD_ASK, "signs", SAY_MOD_PRIORITY_DEFAULT + 1)
	selector.add_saymod(SAY_MOD_EXCLAIM, "signs", SAY_MOD_PRIORITY_DEFAULT + 1)
	selector.add_saymod(SAY_MOD_SING, "rythmically signs", SAY_MOD_PRIORITY_DEFAULT + 1)
	selector.add_saymod(SAY_MOD_WHISPER, "subtly signs", SAY_MOD_PRIORITY_DEFAULT + 1)
	selector.add_saymod(SAY_MOD_WHISPER_YELL, "signs", SAY_MOD_PRIORITY_DEFAULT + 1)
	selector.add_saymod(SAY_MOD_YELL, "emphatically signs", SAY_MOD_PRIORITY_DEFAULT + 1)

/datum/language/sign_language/scramble_paragraph(input, list/mutual_languages)
	if(length(mutual_languages))
		return ..()
	return "makes a series of [pick("unknown", "strange", "foreign", "exaggerated", "eccentric")] gestures"

/datum/language/sign_language/scramble_word(input)
	return "??"

/datum/language/sign_language/can_atom_speak_language(atom/movable/some_atom, feedback)
	return TRUE

/datum/language/sign_language/can_atom_speak(atom/movable/some_atom, allow_mimes, feedback)
	if(!iscarbon(some_atom))
		return TRUE

	var/mob/living/carbon/carbon_parent = some_atom
	if(!allow_mimes && HAS_MIND_TRAIT(carbon_parent, TRAIT_MIMING))
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

	if(HAS_TRAIT_NOT_FROM(carbon_parent, TRAIT_RESTRAINED, HANDCUFFED_TRAIT))
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

/datum/language/sign_language/proc/get_unfilled_hands(mob/living/carbon/carbon_parent)
	var/hands = carbon_parent.usable_hands
	for(var/obj/item/held_item as anything in carbon_parent.get_held_items())
		// items like slappers/zombie claws/etc. should be ignored
		if(held_item.item_flags & HAND_ITEM)
			continue

		hands -= 1

	return hands

/datum/language/sign_language/common
	name = "Galactic Sign Language"
	desc = "A universal sign language used for non-verbal communication across the galaxy."

/datum/language/sign_language/lizard
	name = "Draconic Sign Language"
	desc = "A sign language used by Lizardfolk for non-verbal communication. \
		Unlike Galactic Sign Language, Draconic Sign Language makes heavy use of tail movement."

/datum/language/sign_language/lizard/get_unfilled_hands(mob/living/carbon/carbon_parent)
	if(carbon_parent.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL))
		return ..()

	return ..() - 1

/datum/language/sign_language/moth
	name = "Mothic Sign Language"
	desc = "A sign language used by Mothpeople for non-verbal communication. \
		Unlike Galactic Sign Language, Mothic Sign Language makes heavy use of wing and antennae movement."

/datum/language/sign_language/moth/get_unfilled_hands(mob/living/carbon/carbon_parent)
	if(carbon_parent.get_organ_slot(ORGAN_SLOT_EXTERNAL_WINGS) && carbon_parent.get_organ_slot(ORGAN_SLOT_EXTERNAL_ANTENNAE))
		return ..()

	return ..() - 1

/datum/language/sign_language/spacer
	name = "Spacer Sign Language"
	desc = "A sign language used by Spacers for emergency communication in the event of communications failure during EVA."
	mutual_sign_language_understanding = 50

// Handles the tonal indicator overlay
/datum/status_effect/tonal_indicator
	id = "tonal_indicator"
	alert_type = null
	duration = 2.5 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REPLACE
	/// What type of tone are we conveying
	var/tone_type

/datum/status_effect/tonal_indicator/on_creation(mob/living/new_owner, tone_type = TONE_NEUTRAL)
	src.tone_type = tone_type
	return ..()

/datum/status_effect/tonal_indicator/on_apply()
	if(tone_type == TONE_NEUTRAL)
		return FALSE
	if(!owner.client?.typing_indicators)
		return FALSE

	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	owner.update_appearance(UPDATE_OVERLAYS)
	return TRUE

/datum/status_effect/tonal_indicator/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_appearance(UPDATE_OVERLAYS)

/datum/status_effect/tonal_indicator/proc/on_update_overlays(datum/source, list/overlays)
	SIGNAL_HANDLER

	overlays += mutable_appearance('icons/mob/effects/talk.dmi', "signlang[tone_type]", TYPING_LAYER)

#undef TONE_NEUTRAL
#undef TONE_INQUISITIVE
#undef TONE_EMPHATIC
#undef TONE_INQUISITIVE_EMPHATIC
