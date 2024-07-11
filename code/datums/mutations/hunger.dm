/datum/mutation/human/hungry
	name = "Hyper-Active Digestive System"
	desc = "The host's digestive system is hyper-active, causing you to require food more often."
	quality = NEGATIVE
	text_gain_indication = span_notice("You feel hungrier.")
	instability = NEGATIVE_STABILITY_MINOR
	difficulty = 8

/datum/mutation/human/blood/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	owner.physiology.hunger_mod *= 10

/datum/mutation/human/blood/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return
	if(QDELING(owner))
		return

	owner.physiology.hunger_mod /= 10

/datum/mutation/human/less_hungry
	name = "Hypo-Active Digestive System"
	desc = "The host's digestive system is sluggish, causing you to require food less often."
	quality = POSITIVE
	text_gain_indication = span_notice("You feel less hungry.")
	instability = POSITIVE_INSTABILITY_MINOR
	difficulty = 12

/datum/mutation/human/less_hungry/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	owner.physiology.hunger_mod *= 0.25

/datum/mutation/human/less_hungry/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return
	if(QDELING(owner))
		return

	owner.physiology.hunger_mod /= 0.25
