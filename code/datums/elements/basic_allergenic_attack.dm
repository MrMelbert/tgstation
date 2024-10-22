/// Attach to basic mobs, when they attack, they may trigger a food-based allergic reaction in the target.
/datum/element/basic_allergenic_attack
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	/// What allergen is being used. Corresponds to a FOODTYPE
	var/allergen = NONE
	/// Chance of the reaction happening
	var/allergen_chance = 100

/datum/element/basic_allergenic_attack/Attach(datum/target, allergen = NONE, allergen_chance = 100)
	. = ..()
	if(!isbasicmob(target))
		return ELEMENT_INCOMPATIBLE

	src.allergen = allergen
	src.allergen_chance = allergen_chance
	RegisterSignal(target, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(trigger_allergy))

/datum/element/basic_allergenic_attack/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_HOSTILE_POST_ATTACKINGTARGET)

/datum/element/basic_allergenic_attack/proc/trigger_allergy(datum/source, mob/living/target, result)
	SIGNAL_HANDLER

	if(result <= 0 || !istype(target))
		return

	target.check_allergic_reaction(allergen, allergen_chance)
