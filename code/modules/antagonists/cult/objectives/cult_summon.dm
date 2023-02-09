/datum/objective/eldergod
	var/summoned = FALSE
	var/killed = FALSE

/datum/objective/eldergod/update_explanation_text()
	explanation_text = "Summon Nar'Sie by invoking the rune 'Summon Nar'Sie'. \
		The summoning can only be accomplished in [english_list(team.ritual_sites)] - where the veil is weak enough for the ritual to begin."

/datum/objective/eldergod/check_completion()
	if(killed)
		return CULT_NARSIE_KILLED // You failed so hard that even the code went backwards.
	return summoned || completed
