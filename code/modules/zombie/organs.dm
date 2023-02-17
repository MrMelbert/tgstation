/obj/item/organ/internal/zombie_infection
	name = "festering ooze"
	desc = "A black web of pus and viscera."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_ZOMBIE
	icon_state = "blacktumor"
	var/causes_damage = TRUE
	var/datum/species/old_species = /datum/species/human
	var/living_transformation_time = 30
	var/converts_living = FALSE

	var/revive_time_min = 450
	var/revive_time_max = 700
	var/timer_id

/obj/item/organ/internal/zombie_infection/Initialize(mapload)
	. = ..()
	if(iscarbon(loc))
		Insert(loc)
	GLOB.zombie_infection_list += src

/obj/item/organ/internal/zombie_infection/Destroy()
	GLOB.zombie_infection_list -= src
	. = ..()

/obj/item/organ/internal/zombie_infection/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/organ/internal/zombie_infection/Remove(mob/living/carbon/M, special = FALSE)
	. = ..()
	STOP_PROCESSING(SSobj, src)
	if(iszombie(M) && old_species && !special && !QDELETED(src))
		M.set_species(old_species)
	if(timer_id)
		deltimer(timer_id)

/obj/item/organ/internal/zombie_infection/on_find(mob/living/finder)
	to_chat(finder, "<span class='warning'>Inside the head is a disgusting black \
		web of pus and viscera, bound tightly around the brain like some \
		biological harness.</span>")

/obj/item/organ/internal/zombie_infection/process(delta_time, times_fired)
	if(!owner)
		return
	if(!(src in owner.internal_organs))
		Remove(owner)
	if(owner.mob_biotypes & MOB_MINERAL)//does not process in inorganic things
		return
	if (causes_damage && !iszombie(owner) && owner.stat != DEAD)
		owner.adjustToxLoss(0.5 * delta_time)
		if (DT_PROB(5, delta_time))
			to_chat(owner, span_danger("You feel sick..."))
	if(timer_id)
		return
	if(owner.suiciding)
		return
	if(owner.stat != DEAD && !converts_living)
		return
	if(!owner.getorgan(/obj/item/organ/internal/brain))
		return
	if(!iszombie(owner))
		to_chat(owner, "<span class='cultlarge'>You can feel your heart stopping, but something isn't right... \
		life has not abandoned your broken form. You can only feel a deep and immutable hunger that \
		not even death can stop, you will rise again!</span>")
	var/revive_time = rand(revive_time_min, revive_time_max)
	var/flags = TIMER_STOPPABLE
	timer_id = addtimer(CALLBACK(src, PROC_REF(zombify), owner), revive_time, flags)

/obj/item/organ/internal/zombie_infection/proc/zombify(mob/living/carbon/target)
	timer_id = null

	if(!converts_living && owner.stat != DEAD)
		return

	if(!iszombie(owner))
		old_species = owner.dna.species.type
		target.set_species(/datum/species/zombie/infectious)

	var/stand_up = (target.stat == DEAD) || (target.stat == UNCONSCIOUS)

	//Fully heal the zombie's damage the first time they rise
	if(!target.heal_and_revive(0, span_danger("[target] suddenly convulses, as [target.p_they()][stand_up ? " stagger to [target.p_their()] feet and" : ""] gain a ravenous hunger in [target.p_their()] eyes!")))
		return

	to_chat(target, span_alien("You HUNGER!"))
	to_chat(target, span_alertalien("You are now a zombie! Do not seek to be cured, do not help any non-zombies in any way, do not harm your zombie brethren and spread the disease by killing others. You are a creature of hunger and violence."))
	playsound(target, 'sound/hallucinations/far_noise.ogg', 50, 1)
	target.do_jitter_animation(living_transformation_time)
	target.Stun(living_transformation_time)

/obj/item/organ/internal/zombie_infection/nodamage
	causes_damage = FALSE


/datum/status_effect/zombified
	id = "zombification"
	duration = -1
	tick_interval = -1

/datum/status_effect/zombified/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_ZOMBIFIED, SPECIES_TRAIT)

/datum/status_effect/zombified/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_ZOMBIFIED, SPECIES_TRAIT)

/datum/status_effect/zombified/cosmetic
	id = "cosmetic_zombification"

/datum/status_effect/zombified/infectious
	id = "infectious_zombification"
	tick_interval = 2 SECONDS

	/// The rate the zombies regenerate at
	var/heal_rate = 0.5
	/// The cooldown before the zombie can start regenerating
	COOLDOWN_DECLARE(regen_cooldown)

	var/static/list/spooks = list(
		'sound/hallucinations/growl1.ogg',
		'sound/hallucinations/growl2.ogg',
		'sound/hallucinations/growl3.ogg',
		'sound/hallucinations/veryfar_noise.ogg',
		'sound/hallucinations/wail.ogg',
	)
	var/static/list/zombie_traits = list(
		TRAIT_EASILY_WOUNDED,
		TRAIT_EASYDISMEMBER,
		TRAIT_FAKEDEATH,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOBREATH,
		TRAIT_NOCLONELOSS,
		TRAIT_NODEATH,
		TRAIT_NOHUNGER,
		TRAIT_NOMETABOLISM,
		TRAIT_NO_BODY_TEMPERATURE_REGULATION,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_TOXIMMUNE,
	)

/datum/status_effect/zombified/infectious/on_apply()
	. = ..()
	for(var/trait in zombie_traits)
		ADD_TRAIT(owner, trait, SPECIES_TRAIT)
	owner.AddComponent(/datum/component/mutant_hands, mutant_hand_path = /obj/item/mutant_hand/zombie)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/zombie)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))

	var/obj/item/organ/internal/zombie_infection/infection = owner.getorganslot(ORGAN_SLOT_ZOMBIE)
	if(isnull(infection))
		infection = new()
		infection.Insert(owner)

	var/datum/species/modify_species = owner.dna?.species
	if(!isnull(modify_species))
		owner.mob_biotypes |= MOB_UNDEAD

		modify_species.liked_food |= ZOMBIE_FAVORITES

		modify_species.armor += 20
		modify_species.mutantliver = null
		modify_species.mutantlungs = null
		modify_species.mutantheart = null
		modify_species.mutantstomach = null

		/*
		mutanteyes = /obj/item/organ/internal/eyes/night_vision/zombie
		mutantbrain = /obj/item/organ/internal/brain/zombie
		mutanttongue = /obj/item/organ/internal/tongue/zombie
		*/

	owner.physiology.add_max_stun_duration(2 SECONDS)

/datum/status_effect/zombified/infectious/on_remove()
	. = ..()
	for(var/trait in zombie_traits)
		REMOVE_TRAIT(owner, trait, SPECIES_TRAIT)
	qdel(owner.GetComponent(/datum/component/mutant_hands))
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/zombie)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE)
	UnregisterSignal(owner, COMSIG_LIVING_DEATH)

	owner.mob_biotypes &= ~MOB_UNDEAD // melbert todo: removes existing undead

	var/obj/item/organ/internal/zombie_infection/infection = owner.getorganslot(ORGAN_SLOT_ZOMBIE)
	if(!isnull(infection))
		qdel(infection)

	var/datum/species/modify_species = owner.dna?.species
	if(!isnull(modify_species))
		owner.mob_biotypes = initial(modify_species.inherent_biotypes)

		modify_species.liked_food = initial(modify_species.liked_foods)

		modify_species.armor -= 20
		modify_species.mutantliver = initial(modify_species.mutantliver)
		modify_species.mutantlungs = initial(modify_species.mutantlungs)
		modify_species.mutantheart = initial(modify_species.mutantheart)
		modify_species.mutantstomach = initial(modify_species.mutantstomach)

	owner.physiology.remove_max_stun_duration(2 SECONDS)

/datum/status_effect/zombified/infectious/tick(delta_time, times_fired)
	owner.set_combat_mode(TRUE) // THE SUFFERING MUST FLOW

	//Zombies never actually die, they just fall down until they regenerate enough to rise back up.
	//They must be restrained, beheaded or gibbed to stop being a threat.
	if(COOLDOWN_FINISHED(src, regen_cooldown))
		var/heal_amt = heal_rate
		if(HAS_TRAIT(owner, TRAIT_CRITICAL_CONDITION))
			heal_amt *= 2
		owner.heal_overall_damage(heal_amt * delta_time, heal_amt * delta_time)
		owner.adjustToxLoss(-heal_amt * delta_time)
		for(var/datum/wound/scratch as anything in owner.all_wounds)
			if(DT_PROB(2 - (scratch.severity / 2), delta_time))
				scratch.remove_wound()

	if(!HAS_TRAIT(owner, TRAIT_CRITICAL_CONDITION) && DT_PROB(2, delta_time))
		playsound(owner, pick(spooks), 50, TRUE, 10)

/datum/status_effect/zombified/infectious/proc/on_damage(datum/source, damage)
	SIGNAL_HANDLER

	if(damage < 0)
		return

	COOLDOWN_START(src, regen_cooldown, ZOMBIE_REGENERATION_DELAY)

/datum/status_effect/zombified/infectious/proc/on_death(datum/source, gibbed)
	SIGNAL_HANDLER

	// Congrats, you somehow died so hard you stopped being a zombie
	qdel(src)

/datum/movespeed_modifier/zombie
	movetypes = ~FLYING
	multiplicative_slowdown = 1.6
