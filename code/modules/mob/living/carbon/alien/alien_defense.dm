
/mob/living/carbon/alien/get_eye_protection()
	return ..() + 2 //potential cyber implants + natural eye protection

/mob/living/carbon/alien/get_ear_protection()
	return 2 //no ears

/mob/living/carbon/alien/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	..(AM, skipcatch = TRUE, hitpush = FALSE)

/*Code for aliens attacking aliens. Because aliens act on a hivemind, I don't see them as very aggressive with each other.
As such, they can either help or harm other aliens. Help works like the human help command while harm is a simple nibble.
In all, this is a lot like the monkey code. /N
*/
/mob/living/carbon/alien/attack_alien(mob/living/carbon/alien/user, list/modifiers)
	if(!user.combat_mode)
		if(user == src && check_self_for_injuries())
			return
		set_resting(FALSE)
		AdjustStun(-60)
		AdjustKnockdown(-60)
		AdjustImmobilized(-60)
		AdjustParalyzed(-60)
		AdjustUnconscious(-60)
		AdjustSleeping(-100)
		visible_message(span_notice("[user.name] nuzzles [src] trying to wake [p_them()] up!"))
	else if(health > 0)
		user.do_attack_animation(src, ATTACK_EFFECT_BITE)
		playsound(loc, 'sound/weapons/bite.ogg', 50, TRUE, -1)
		visible_message(span_danger("[user.name] bites [src]!"), \
						span_userdanger("[user.name] bites you!"), span_hear("You hear a chomp!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_danger("You bite [src]!"))
		adjustBruteLoss(1)
		log_combat(user, src, "attacked")
		updatehealth()
	else
		to_chat(user, span_warning("[name] is too injured for that."))


/mob/living/carbon/alien/attack_larva(mob/living/carbon/alien/larva/L, list/modifiers)
	return attack_alien(L)


/mob/living/carbon/alien/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(.) //to allow surgery to return properly.
		return FALSE

	var/martial_result = user.apply_martial_art(src, modifiers)
	if (martial_result != MARTIAL_ATTACK_INVALID)
		return martial_result

	if(user.combat_mode)
		if(LAZYACCESS(modifiers, RIGHT_CLICK))
			user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
			return TRUE
		user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
		return TRUE
	else
		help_shake_act(user)


/mob/living/carbon/alien/attack_paw(mob/living/carbon/human/user, list/modifiers)
	if(..())
		if (stat != DEAD)
			var/obj/item/bodypart/affecting = get_bodypart(get_random_valid_zone(user.zone_selected))
			apply_damage(rand(1, 3), BRUTE, affecting)


/mob/living/carbon/alien/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		var/damage = rand(user.melee_damage_lower, user.melee_damage_upper)
		switch(user.melee_damage_type)
			if(BRUTE)
				adjustBruteLoss(damage)
			if(BURN)
				adjustFireLoss(damage)
			if(TOX)
				adjustToxLoss(damage)
			if(OXY)
				adjustOxyLoss(damage)
			if(CLONE)
				adjustCloneLoss(damage)
			if(STAMINA)
				adjustStaminaLoss(damage)

/mob/living/carbon/alien/attack_slime(mob/living/simple_animal/slime/M, list/modifiers)
	if(..()) //successful slime attack
		var/damage = rand(5, 35)
		if(M.is_adult)
			damage = rand(10, 40)
		adjustBruteLoss(damage)
		log_combat(M, src, "attacked")
		updatehealth()

/mob/living/carbon/alien/ex_act(severity, target, origin)
	. = ..()
	if(!. || QDELETED(src))
		return FALSE

	var/obj/item/organ/internal/ears/ears = get_organ_slot(ORGAN_SLOT_EARS)
	switch (severity)
		if (EXPLODE_DEVASTATE)
			gib()

		if (EXPLODE_HEAVY)
			take_overall_damage(60, 60)
			if(ears)
				ears.adjustEarDamage(30,120)

		if(EXPLODE_LIGHT)
			take_overall_damage(30,0)
			if(prob(50))
				Unconscious(20)
			if(ears)
				ears.adjustEarDamage(15,60)

	return TRUE


/mob/living/carbon/alien/soundbang_act(intensity = 1, stun_pwr = 20, damage_pwr = 5, deafen_pwr = 15)
	return 0

/mob/living/carbon/alien/acid_act(acidpwr, acid_volume)
	return FALSE//aliens are immune to acid.

/mob/living/carbon/alien/on_fire_stack(seconds_per_tick, times_fired, datum/status_effect/fire_handler/fire_stacks/fire_handler)
	adjust_bodytemperature((BODYTEMP_HEATING_MAX + (fire_handler.stacks * 12)) * 0.5 * seconds_per_tick)
