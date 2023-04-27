/datum/action/cooldown/spell/touch/cult_stun
	name = "Stun"
	desc = "Will stun and mute a weak-minded victim on contact."
	DEFINE_CULT_ACTION("hand", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "Fuu ma'jin!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	hand_path = /obj/item/melee/touch_attack/cult/stun

/datum/action/cooldown/spell/touch/cult_stun/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell/blood_cost, charges = 1, health_cost = 10)

/datum/action/cooldown/spell/touch/cult_stun/is_valid_target(atom/cast_on)
	var/mob/living/living_cast_on = cast_on
	return istype(living_cast_on) && !IS_CULTIST(living_cast_on)

/datum/action/cooldown/spell/touch/cult_stun/cast_on_hand_hit(obj/item/melee/touch_attack/hand, mob/living/victim, mob/living/carbon/caster)
	caster.visible_message(
		span_warning("[caster] holds up [caster.p_their()] hand, which explodes in a flash of red light!"),
		span_cultitalic("You attempt to stun [victim] with the spell!"),
	)

	caster.mob_light(_range = 3, _color = LIGHT_COLOR_BLOOD_MAGIC, _duration = 0.2 SECONDS)

	if(victim.can_block_magic(antimagic_flags))
		to_chat(caster, span_warning("The spell had no effect!"))
		return TRUE

	var/sigreturn = SEND_SIGNAL(victim, COMSIG_LIVING_CULT_STUNNED, caster, hand, src)
	if(sigreturn & FAIL_CULT_STUN)
		return FALSE // Stun failed, stop the cast, don't consume it
	if(sigreturn & BLOCK_CULT_STUN)
		return TRUE // Stun succeeded but was blocked

	to_chat(caster, span_cultitalic("In a brilliant flash of red, [victim] falls to the ground!"))
	victim.Paralyze(16 SECONDS)
	victim.flash_act(1, TRUE)
	if(issilicon(victim))
		var/mob/living/silicon/silicon_target = victim
		silicon_target.emp_act(EMP_HEAVY)
	else if(iscarbon(victim))
		var/mob/living/carbon/carbon_target = victim
		carbon_target.adjust_silence(12 SECONDS)
		carbon_target.adjust_stutter(30 SECONDS)
		carbon_target.set_jitter_if_lower(30 SECONDS)
		carbon_target.adjust_timed_status_effect(30 SECONDS, /datum/status_effect/speech/slurring/cult)
	return TRUE

/obj/item/melee/touch_attack/cult/stun
	name = "stunning aura"
	desc = "Will stun and mute a weak-minded victim on contact."
	color = RUNE_COLOR_RED
