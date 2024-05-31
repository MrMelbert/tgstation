/// Tesla Coil
/// Getting zapped propagates the shock to nearby targets.
/datum/mutation/human/tesla
	name = "Tesla Coil"
	desc = "Being shocked by electricity will cause the shock to propagate to nearby targets."
	quality = POSITIVE
	text_gain_indication = span_notice("You feel a strange tingling sensation.")
	instability = 15
	locked = TRUE
	power_coeff = 1

/datum/mutation/human/tesla/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	RegisterSignal(owner, COMSIG_LIVING_ELECTROCUTE_ACT, PROC_REF(propagate_electrocution))
	// put batons, tasers, defib here

/datum/mutation/human/tesla/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	UnregisterSignal(owner, COMSIG_LIVING_ELECTROCUTE_ACT)

/datum/mutation/human/tesla/proc/propagate_electrocution(mob/living/carbon/human/source, shock_damage, shock_source, siemens_coeff, flag)
	SIGNAL_HANDLER

	if(shock_source == source)
		return
	if(flag & SHOCK_ILLUSION)
		return

	// Don't zap ourselves please
	ADD_TRAIT(source, TRAIT_TESLA_SHOCKIMMUNE, REF(src))
	addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_TESLA_SHOCKIMMUNE, REF(src)), 0.5 SECONDS)
	// Zap again
	tesla_zap(source = source, zap_range = ceil(GET_MUTATION_POWER(src) * 3), power = shock_damage, zap_flags = flag|SHOCK_KNOCKDOWN)
