// Future todo : replace this by just adding the relevant trait when lungs are removed
/mob/living/carbon/is_mute()
	if(isnull(dna?.species))
		return ..()

	// If we're not a nobreath species, and we don't have lungs, we can't talk
	if(HAS_TRAIT_FROM(src, TRAIT_MUTE, SPECIES_TRAIT))
		return ..()

	// How do species that don't breathe, talk? Magic, that's what.
	if(!get_organ_slot(ORGAN_SLOT_LUNGS))
		return TRUE

	return ..()
