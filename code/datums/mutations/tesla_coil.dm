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
	RegisterSignal(owner, COMSIG_LIVING_MINOR_SHOCK, PROC_REF(propagate_minor_shock))

/datum/mutation/human/tesla/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	UnregisterSignal(owner, COMSIG_LIVING_ELECTROCUTE_ACT)
	UnregisterSignal(owner, COMSIG_LIVING_MINOR_SHOCK)

/datum/mutation/human/tesla/proc/propagate_electrocution(mob/living/carbon/human/source, shock_damage, shock_source, siemens_coeff, flag)
	SIGNAL_HANDLER

	if(shock_source == source)
		return
	if(flag & SHOCK_ILLUSION)
		return
	var/zap_flags = ZAP_MOB_DAMAGE|ZAP_MOB_STUN
	if(flag & (SHOCK_NOSTUN|SHOCK_DELAY_STUN|SHOCK_KNOCKDOWN))
		zap_flags &= ~ZAP_MOB_STUN

	// Don't zap ourselves please
	ADD_TRAIT(source, TRAIT_TESLA_SHOCKIMMUNE, REF(src))
	addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_TESLA_SHOCKIMMUNE, REF(src)), 0.5 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
	// Zap again
	tesla_zap(
		source = source,
		zap_range = ceil(GET_MUTATION_POWER(src) * 3),
		power = clamp(shock_damage * POWER_TO_DAMAGE_MULTIPLIER * 0.5, 5 KILO JOULES, 50 KILO JOULES),
		zap_flags = zap_flags,
	)

/datum/mutation/human/tesla/proc/propagate_minor_shock(mob/living/carbon/human/source)
	SIGNAL_HANDLER

	// Basically fake that a shock happened
	ADD_TRAIT(source, TRAIT_TESLA_SHOCKIMMUNE, REF(src))
	addtimer(TRAIT_CALLBACK_REMOVE(src, TRAIT_TESLA_SHOCKIMMUNE, REF(src)), 0.5 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
	// Send the fake shock
	tesla_zap(
		source = source,
		zap_range = ceil(GET_MUTATION_POWER(src) * 2), power = (10 KILO JOULES),
		zap_flags = ZAP_MOB_DAMAGE, // Don't make this a stun zap or med+sec will cry
	)
