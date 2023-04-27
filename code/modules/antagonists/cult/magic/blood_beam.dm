/// Not a default cult spell.
/// This is the blood beam invoked by using blood rites.
/datum/action/cooldown/spell/pointed/blood_beam
	name = "Blood Beam"
	desc = "Fires off an incredibly powerful cone of blood beams at the direction you point. \
		This spell has a long charge up time that will leave you vulnerable before and after casting. \
		Heathens hit by the beam will be damaged and stunned, while fellow cultists will be healed. \
		Additionally, the ground beneath it will be converted."
	DEFINE_CULT_ACTION("disintegrate", 'icons/obj/weapons/items_and_weapons.dmi')

	default_button_position = DEFAULT_UNIQUE_BLOODSPELLS

	sound = null
	invocation_type = INVOCATION_NONE
	cooldown_time = 20 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	cast_range = 40 // So we can click on far away things - doesn't matter much regardless

	/// Angle set in cast for where the beams will start to fire.
	VAR_FINAL/beam_angle = 0
	/// Whether we're currently charging
	VAR_FINAL/beam_charging = FALSE
	/// Whether we're currently firing
	VAR_FINAL/beam_firing = FALSE

	/// If TRUE, after a successful cast where we started firing, the spell self deletes
	var/delete_after_fire = TRUE

/datum/action/cooldown/spell/pointed/blood_beam/can_cast_spell(feedback)
	return ..() && isliving(owner) && !beam_charging && !beam_firing && isturf(owner.loc)

/datum/action/cooldown/spell/pointed/blood_beam/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	beam_charging = TRUE
	beam_angle = get_angle(owner, cast_on)
	INVOKE_ASYNC(src, PROC_REF(charge_effects), owner)

/datum/action/cooldown/spell/pointed/blood_beam/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	if(!do_after(caster, 9 SECONDS))
		return

	beam_firing = TRUE
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, CULT_TRAIT)
	INVOKE_ASYNC(src, PROC_REF(pewpew), caster)// melbert todo, this probably shouldn't be async, fragile
	var/obj/structure/emergency_shield/cult/weak/protection = new(owner.loc)
	if(do_after(caster, 9 SECONDS))
		caster.Paralyze(4 SECONDS)
		to_chat(caster, span_cultitalic("You have exhausted the power of this spell!"))
	REMOVE_TRAIT(caster, TRAIT_IMMOBILIZED, CULT_TRAIT)
	qdel(protection)

/datum/action/cooldown/spell/pointed/blood_beam/after_cast(atom/cast_on)
	. = ..()
	if(beam_firing && delete_after_fire)
		qdel(src)
	beam_firing = FALSE
	beam_charging = FALSE

/datum/action/cooldown/spell/pointed/blood_beam/proc/charge_effects(mob/living/caster)
	var/obj/visual_holder
	playsound(caster, 'sound/magic/lightning_chargeup.ogg', 100, FALSE)
	for(var/i in 1 to 12)
		if(!beam_charging || QDELETED(caster) || QDELETED(src))
			break
		if(i > 1)
			stoplag(1.5 SECONDS)
		if(i < 4)
			visual_holder = new /obj/effect/temp_visual/cult/rune_spawn/rune1/inner(caster.loc, 3 SECONDS, "#ff0000")
		else
			visual_holder = new /obj/effect/temp_visual/cult/rune_spawn/rune5(caster.loc, 3 SECONDS, "#ff0000")
			new /obj/effect/temp_visual/dir_setting/cult/phase/out(caster.loc, caster.dir)

	qdel(visual_holder)

/datum/action/cooldown/spell/pointed/blood_beam/proc/pewpew()
	var/turf/targets_from = get_turf(owner)
	var/spread = 40
	var/second = FALSE
	var/set_angle = beam_angle
	for(var/i in 1 to 12)
		if(second)
			set_angle = beam_angle - spread
			spread -= 8
		else
			stoplag(1.5 SECONDS)
			set_angle = beam_angle + spread
		second = !second //Handles beam firing in pairs
		if(!beam_firing || QDELETED(src) || QDELETED(owner))
			break
		playsound(owner, 'sound/magic/exit_blood.ogg', 75, TRUE)
		new /obj/effect/temp_visual/dir_setting/cult/phase(owner.loc, owner.dir)

		var/turf/temp_target = get_turf_in_angle(set_angle, targets_from, 40)
		for(var/turf/beamed as anything in get_line(targets_from, temp_target))
			if(HAS_TRAIT(beamed, TRAIT_HOLY))
				temp_target = beamed
				playsound(beamed, 'sound/machines/clockcult/ark_damage.ogg', 50, TRUE)
				new /obj/effect/temp_visual/at_shield(beamed, beamed)
				break

			beamed.narsie_act(/* force = */TRUE, /* ignore_mobs = */TRUE)
			if(locate(/mob) in beamed) // don't waste our time if no one's here
				INVOKE_ASYNC(src, PROC_REF(effect_to_mobs), targets_from, beamed)

		owner.Beam(temp_target, icon_state = "blood_beam", time = 0.7 SECONDS, beam_type = /obj/effect/ebeam/blood)

/datum/action/cooldown/spell/pointed/blood_beam/proc/effect_to_mobs(atom/source, turf/locale)
	var/sparkled = FALSE
	var/dir_to_us = get_dir(source, locale)
	for(var/mob/living/hit in locale)
		if(IS_CULTIST(hit))
			if(!sparkled)
				new /obj/effect/temp_visual/cult/sparks(locale)
				sparkled = TRUE

			if(ishuman(hit) && hit.reagents && hit.stat != DEAD)
				hit.reagents.add_reagent(/datum/reagent/fuel/unholywater, 7)

			if(isshade(target) || isconstruct(target))
				var/mob/living/simple_animal/cult_creature = hit
				cult_creature.adjustHealth(-15)
			return
		if(!hit.density) // Revenants? I think?
			continue
		hit.Paralyze(2 SECONDS)
		hit.apply_damage(45, BRUTE, spread_damage = TRUE, wound_bonus = CANT_WOUND, attack_direction = dir_to_us)
		playsound(hit, 'sound/hallucinations/wail.ogg', 50, TRUE)
		hit.emote("scream")

/obj/effect/ebeam/blood
	name = "blood beam"
