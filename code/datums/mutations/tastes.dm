/datum/mutation/human/tasteless
	name = "Tasteless"
	desc = "The host's taste buds are dulled, making them unable to taste anything."
	text_gain_indication = span_danger("Your sense of taste seems to disappear.")
	quality = POSITIVE
	difficulty = 12
	instability = POSITIVE_INSTABILITY_MINI
	mutation_traits = list(TRAIT_AGEUSIA)

/datum/mutation/human/taste
	name = "Carnivorous"
	desc = "The carnivorous genome, often found in predators, allows the host to consume raw meat without any ill effects."
	text_gain_indication = span_notice("You feel primal.")
	quality = POSITIVE
	difficulty = 12
	instability = 0
	/// What flags do we toggle on their tongue
	VAR_PROTECTED/given_flags = RAW|MEAT|GORE

/datum/mutation/human/taste/on_acquiring(mob/living/carbon/human/acquirer)
	. = ..()
	if(.)
		return

	RegisterSignal(acquirer, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(tongue_gained))
	RegisterSignal(acquirer, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(tongue_lost))
	tongue_gained(acquirer, acquirer.get_organ_by_type(/obj/item/organ/internal/tongue))

/datum/mutation/human/taste/on_losing(mob/living/carbon/human/acquirer)
	. = ..()
	if(.)
		return
	UnregisterSignal(acquirer, list(COMSIG_CARBON_GAIN_ORGAN, COMSIG_CARBON_LOSE_ORGAN))
	if(QDELING(acquirer))
		return

	tongue_lost(acquirer, acquirer.get_organ_by_type(/obj/item/organ/internal/tongue))

/datum/mutation/human/taste/proc/tongue_gained(datum/source, obj/item/tongue)
	SIGNAL_HANDLER

	if(!istype(tongue, /obj/item/organ/internal/tongue))
		return

	enable_mutation(tongue)

/datum/mutation/human/taste/proc/enable_mutation(obj/item/organ/internal/tongue/tongue)
	given_flags &= ~tongue.liked_foodtypes // flip off all the flags that they already have
	tongue.liked_foodtypes |= given_flags

/datum/mutation/human/taste/proc/tongue_lost(datum/source, obj/item/tongue)
	SIGNAL_HANDLER

	if(!istype(tongue, /obj/item/organ/internal/tongue))
		return

	disable_mutation(tongue)

/datum/mutation/human/taste/proc/disable_mutation(obj/item/organ/internal/tongue/tongue)
	tongue.liked_foodtypes &= ~given_flags
	given_flags = initial(given_flags)

/datum/mutation/human/taste/hate_everything
	name = "Revolting Buds"
	desc = "The host's taste buds are hypersensitive, making them unable to enjoy eating anything."
	text_gain_indication = span_danger("You feel disgusted by everything.")
	quality = NEGATIVE
	instability = NEGATIVE_STABILITY_MINOR
	/// Tracks all the likes we remove
	VAR_PRIVATE/removed_likes = NONE
	/// Tracks all the hates we add
	VAR_PRIVATE/removed_hates = NONE

/datum/mutation/human/taste/hate_everything/enable_mutation(obj/item/organ/internal/tongue/tongue)
	removed_likes = tongue.liked_foodtypes
	tongue.liked_foodtypes = NONE
	removed_hates = tongue.disliked_foodtypes
	tongue.disliked_foodtypes = ALL

/datum/mutation/human/taste/hate_everything/disable_mutation(obj/item/organ/internal/tongue/tongue)
	tongue.liked_foodtypes = removed_likes
	tongue.disliked_foodtypes = removed_hates
	removed_likes = NONE
	removed_hates = NONE
