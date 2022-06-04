/// Determines whether you spawn in as a human, or your set species, if you become a nuclear operative
/// If the pref is FALSE, we will remain our pref species instead of being made into a human.
/datum/preference/toggle/nuke_ops_species
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE
	// Make it an opt-in thing.
	default_value = TRUE
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "nuke_ops_species"

/datum/preference/toggle/nuke_ops_species/is_accessible(datum/preferences/preferences)
	. = ..()
	if(!.)
		return FALSE

	// Only show up if we have a nuke ops rule selected
	var/static/list/ops_roles = list(ROLE_OPERATIVE, ROLE_LONE_OPERATIVE, ROLE_OPERATIVE_MIDROUND, ROLE_CLOWN_OPERATIVE)
	if(length(ops_roles & preferences.be_special))
		return TRUE

	return FALSE

/datum/preference/toggle/nuke_ops_species/apply_to_human(mob/living/carbon/human/target, value)
	return
