/// Rapid Blood Regeneration
/// You bleed faster, and regenerate blood faster
/// Basically passive blood regen boost that gets offset while bleeding
/datum/mutation/human/blood_regen
	name = "Active Blood Regeneration"
	desc = "A mutation to the host's circulatory system that allows for rapid regeneration of blood cells."
	quality = POSITIVE
	text_gain_indication = span_notice("Your heart beats faster.")
	instability = 20
	difficulty = 16
	synchronizer_coeff = 1
	power_coeff = 1

	var/bleed_rate_mod = 2
	var/regen_boost_mod = 4

/datum/mutation/human/blood_regen/on_acquiring(mob/living/carbon/human/owner)
	bleed_rate_mod *= GET_MUTATION_SYNCHRONIZER(src)
	regen_boost_mod *= GET_MUTATION_POWER(src)
	modified = TRUE

	. = ..()
	if(.)
		return

	owner.physiology.bleed_mod *= bleed_rate_mod
	owner.blood_regen_factor *= regen_boost_mod

/datum/mutation/human/blood_regen/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return
	if(QDELING(owner))
		return

	owner.physiology.bleed_mod /= bleed_rate_mod
	owner.blood_regen_factor /= regen_boost_mod

/datum/mutation/human/blood_regen/modify()
	owner.physiology.bleed_mod /= bleed_rate_mod
	owner.blood_regen_factor /= regen_boost_mod

	bleed_rate_mod = initial(bleed_rate_mod) * GET_MUTATION_SYNCHRONIZER(src)
	regen_boost_mod = initial(regen_boost_mod) * GET_MUTATION_POWER(src)

	owner.physiology.bleed_mod *= bleed_rate_mod
	owner.blood_regen_factor *= regen_boost_mod
