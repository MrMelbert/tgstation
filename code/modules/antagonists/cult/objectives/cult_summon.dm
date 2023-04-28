/datum/objective/eldergod
	var/summoned = FALSE
	var/killed = FALSE

/datum/objective/eldergod/update_explanation_text()
	if(!istype(team, /datum/team/cult))
		CRASH("Cult summon objective without a cult team associated.")

	var/datum/team/cult/cult = team
	explanation_text = "Summon Nar'Sie by invoking the rune 'Summon Nar'Sie'. \
		The summoning can only be accomplished in [english_list(cult.ritual_sites)] - where the veil is weak enough for the ritual to begin."

/datum/objective/eldergod/check_completion()
	if(killed)
		return -1 // CULT_NARSIE_KILLED // You failed so hard that even the code went backwards.
	return summoned || completed
