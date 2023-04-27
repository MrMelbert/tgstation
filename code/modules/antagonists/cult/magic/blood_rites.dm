#define BLOOD_HALBERD_COST 150
#define BLOOD_BARRAGE_COST 300
#define BLOOD_BEAM_COST 500

#define BLOOD_HALBERD_KEY "Bloody Halberd" // "Bloody Halberd ([BLOOD_HALBERD_COST])"
#define BLOOD_BARRAGE_KEY "Blood Bolt Barrage" // "Blood Bolt Barrage ([BLOOD_BARRAGE_COST])"
#define BLOOD_BEAM_KEY "Blood Beam" // "Blood Beam ([BLOOD_BEAM_COST])"

/**
 * Cult bloat, they name is blood rites
 *
 * This is a touch spell that can do a number of things
 * - Clicking on blood will increment its charges
 * - Clicking on non-cultist humans will steal blood volume from them and also gain charges
 * - Clicking on cultist humans will heal them and restore blood
 * - Clicking on constructs will heal them
 * - Attack-selfing the touch spell will let you summon a very strong melee weapon
 * - Attack-selfing the touch spell will let you get a wizard spell
 * - Attack-selfing the touch spell lets you get a big fuck-off beam spell
 */
/datum/action/cooldown/spell/touch/blood_rites
	name = "Blood Rites"
	desc = "Empowers your hand to absorb blood to be used for advanced rites, or heal a cultist on contact. \
		Use the spell in-hand to cast advanced rites."
	DEFINE_CULT_ACTION("manip", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "Fel'th Dol Ab'orod!"
	invocation_type = INVOCATION_WHISPER
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	hand_path = /obj/item/melee/touch_attack/cult/manipulator
	can_cast_on_self = TRUE

	/// Our blood spell component, which tracks the number of charges we have left.
	/// We must track this, unlike other spells, due to the unique ability of incrementing charges.
	/// Yeah it's a little icky, but cult code is all snowflake code.
	VAR_FINAL/datum/component/charge_spell/charge_tracker
	/// Static list of advanced rites we can invoke.
	/// Used in a radial, so it is a key to image association.
	VAR_FINAL/static/list/advanced_rites = list(
		BLOOD_HALBERD_KEY = image(icon = 'icons/obj/cult/items_and_weapons.dmi', icon_state = "occultpoleaxe0"),
		BLOOD_BARRAGE_KEY = image(icon = 'icons/obj/weapons/guns/ballistic.dmi', icon_state = "arcane_barrage"),
		BLOOD_BEAM_KEY = image(icon = 'icons/obj/weapons/hand.dmi', icon_state = "disintegrate"),
	)

	/// How much blood is taken when casted on a non-cultist human.
	/// Charges are gained equal to this value divided by two.
	var/human_drain_amount = 100

/datum/action/cooldown/spell/touch/blood_rites/New(Target, original)
	. = ..()
	charge_tracker = AddComponent(/datum/component/charge_spell, charges = 5)

/datum/action/cooldown/spell/touch/blood_rites/Destroy()
	charge_tracker = null
	return ..()

/datum/action/cooldown/spell/touch/blood_rites/register_hand_signals()
	. = ..()
	RegisterSignal(attached_hand, COMSIG_PARENT_EXAMINE, PROC_REF(on_hand_examine))
	RegisterSignal(attached_hand, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_hand_attack_self))
	RegisterSignal(attached_hand, COMSIG_ITEM_ATTACK_EFFECT, PROC_REF(on_hand_attack_effect))

/datum/action/cooldown/spell/touch/blood_rites/unregister_hand_signals()
	. = ..()
	UnregisterSignal(attached_hand, list(COMSIG_ITEM_ATTACK_SELF, COMSIG_PARENT_EXAMINE, COMSIG_ITEM_ATTACK_EFFECT))

/// For [COMSIG_PARENT_EXAMINE] to show the advanced rites we can invoke
/datum/action/cooldown/spell/touch/blood_rites/proc/on_hand_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(user != owner)
		return

	var/list/possibilities = list(
		"- [BLOOD_HALBERD_COST] charges allows you to invoke the <b>Blood Halberd</b>, a powerful two-handed melee weapon that is also an effective - \
			though very fragile - throwing weapon. Comes with the ability to recall the weapon to your hands, should it be separated from you.",
		"- [BLOOD_BARRAGE_COST] charges allows you to invoke the <b>Blood Bolt Barrage</b>, a one-use spell which lets you rapidly fire off up to 24 \
			bolts of blood, dealing moderate burns to non-believers while healing fellow cultists and constructs. Dropping the spell will stop it.",
		"- [BLOOD_BEAM_COST] charges allows you to invoke the <b>Blood Beam</b>, a powerful one-use spell which fires off far-reaching beams \
			of cult energy which will heal cultists, harm non-believers, and convert anything it comes in contact with to Nar'sian. \
			The spell takes a moment to charge up, and will leave you vulnerable during and afterwards.",
	)

	examine_list += span_cultbold("<u>Using this in hand will allow you to invoke advanced rites:</u>")
	examine_list += span_cult(jointext(possibilities, "\n"))

/// For [COMSIG_ITEM_ATTACK_SELF], to allow attack-selfing to summon the advanced spells
/datum/action/cooldown/spell/touch/blood_rites/proc/on_hand_attack_self(obj/item/source, mob/user)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(invoke_advanced_rite), user)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// We need to be able to hit blood decals, so we also must implement [COMSIG_ITEM_ATTACK_EFFECT]
/datum/action/cooldown/spell/touch/blood_rites/proc/on_hand_attack_effect(obj/item/source, obj/effect/smacked, mob/user)
	SIGNAL_HANDLER

	on_hand_hit(source, smacked, user, TRUE)
	return COMPONENT_NO_AFTERATTACK

/datum/action/cooldown/spell/touch/blood_rites/proc/invoke_advanced_rite(mob/user)
	var/choice = show_radial_menu(user, attached_hand, advanced_rites, custom_check = CALLBACK(src, PROC_REF(rite_radial), user), require_near = TRUE)
	switch(choice)
		if(BLOOD_HALBERD_KEY)
			if(charge_tracker.charges < BLOOD_HALBERD_COST)
				user.balloon_alert(user, "[BLOOD_HALBERD_COST] charges needed!")
				return
			if(locate(/datum/action/cooldown/spell/summonitem/cult_halberd) in user.actions)
				user.balloon_alert(user, "halberd already invoked!")
				return

			charge_tracker.charges -= BLOOD_HALBERD_COST
			var/datum/action/cooldown/spell/summonitem/cult_halberd/halberd_recall = new(user)
			var/obj/item/melee/cultblade/halberd/halberd = new(user.loc)
			halberd_recall.overlay_icon_state = "ab_goldborder"
			halberd_recall.mark_item(halberd)
			halberd_recall.Grant(user)
			halberd_recall.AddElement(/datum/element/cult_spell)

			remove_hand(user)
			if(user.put_in_hands(halberd))
				user.visible_message(
					span_warning("\A [halberd] appears in [user]'s hands!"),
					span_cultitalic("\A [halberd] materializes in your hands."),
				)
			else
				user.visible_message(
					span_warning("\A [halberd] appears at [user]'s feet!"),
					span_cultitalic("\A [halberd] materializes at your feet."),
				)

		if(BLOOD_BARRAGE_KEY)
			if(charge_tracker.charges < BLOOD_BARRAGE_COST)
				user.balloon_alert(user, "[BLOOD_BARRAGE_COST] charges needed!")
				return
			if(locate(/datum/action/cooldown/spell/conjure_item/infinite_guns/blood_bolt) in user.actions)
				user.balloon_alert(user, "blood bolt barrage already invoked!")
				return

			remove_hand(user)
			var/datum/action/cooldown/spell/conjure_item/infinite_guns/blood_bolt/barrage = new(user)
			barrage.overlay_icon_state = "ab_goldborder"
			barrage.Grant(user)
			barrage.AddElement(/datum/element/cult_spell)
			charge_tracker.charges -= BLOOD_BARRAGE_COST
			to_chat(user, span_cultbold("Your hands glow with power!"))

		if(BLOOD_BEAM_KEY)
			if(charge_tracker.charges < BLOOD_BEAM_COST)
				user.balloon_alert(user, "[BLOOD_BEAM_COST] charges needed!")
				return
			if(locate(/datum/action/cooldown/spell/pointed/blood_beam) in user.actions)
				user.balloon_alert(user, "blood beam already invoked!")
				return

			remove_hand(user)
			var/datum/action/cooldown/spell/pointed/blood_beam/beaaaaaam = new(user)
			beaaaaaam.overlay_icon_state = "ab_goldborder"
			beaaaaaam.Grant(user)
			beaaaaaam.AddElement(/datum/element/cult_spell)
			charge_tracker.charges -= BLOOD_BEAM_COST
			to_chat(user, span_cultlarge("Your hands glow with POWER OVERWHELMING!!!"))

		else
			return

	if(charge_tracker.charges <= 0)
		qdel(src)

/datum/action/cooldown/spell/touch/blood_rites/proc/rite_radial(mob/caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(attached_hand) || !IsAvailable())
		return FALSE
	return TRUE

/datum/action/cooldown/spell/touch/blood_rites/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(isconstruct(victim))
		return heal_construct(victim, caster)

	if(ishuman(victim))
		var/mob/living/carbon/human/human_victim = victim
		if(IS_CULTIST(human_victim))
			return heal_cultist(victim, caster)

		// Should cultists without blood be able to be healed by blood rights? Seems wrong
		if(HAS_TRAIT(human_victim, TRAIT_NOBLOOD) || !human_victim.blood_volume)
			victim.balloon_alert(caster, "no blood!")
			return FALSE

		return drain_victim(victim, caster)

	if(istype(victim, /obj/effect/decal/cleanable/blood)) // melbert todo: you can't cast on /effects
		return absorb_blood(victim, caster)

	return FALSE

/datum/action/cooldown/spell/touch/blood_rites/proc/heal_construct(mob/living/simple_animal/hostile/construct/construct, mob/living/carbon/caster)
	var/missing = construct.maxHealth - construct.health
	if(missing <= 0)
		return FALSE

	if(charge_tracker.charges > missing)
		construct.adjustHealth(-missing)
		construct.visible_message(span_warning("[construct] is fully repaired by [caster]'s blood magic!"))
		charge_tracker.charges -= missing
	else
		construct.adjustHealth(-charge_tracker.charges)
		construct.visible_message(span_warning("[construct] is partially repaired by [caster]'s blood magic!"))
		charge_tracker.charges = 0

	playsound(get_turf(construct), 'sound/magic/staff_healing.ogg', 25)
	caster.Beam(construct, icon_state = "sendbeam", time = 1 SECONDS)
	return TRUE

/datum/action/cooldown/spell/touch/blood_rites/proc/heal_cultist(mob/living/carbon/human/victim, mob/living/carbon/caster)
	if(victim.stat == DEAD)
		victim.balloon_alert("they're dead, use a revival rune!")
		return FALSE
	if(victim.blood_volume < BLOOD_VOLUME_SAFE)
		var/restored_blood = BLOOD_VOLUME_SAFE - victim.blood_volume
		if(charge_tracker.charges * 2 < restored_blood)
			victim.blood_volume += (charge_tracker.charges * 2)
			to_chat(caster, span_danger("You use the last of your blood rites to restore what blood you could[victim == caster ? "" : " for [victim]"]!"))
			charge_tracker.charges = 0
			return TRUE

		victim.blood_volume = BLOOD_VOLUME_SAFE
		charge_tracker.charges -= round(restored_blood / 2)
		to_chat(caster, span_danger("Your blood rites have restored [victim == caster ? "your" : "[victim]'s"] blood to safe levels!"))
		. = TRUE // keep going to see if we can also do some healing

	var/overall_damage = victim.getBruteLoss() + victim.getFireLoss() + victim.getToxLoss() + victim.getOxyLoss()
	if(overall_damage <= 0)
		if(.) // we were successful earlier, so don't give them a failure message. Just return.
			return TRUE

		to_chat(caster, span_warning("[victim == caster ? "You don't" : "[victim] doesn't"] require healing!"))
		return FALSE

	var/ratio = charge_tracker.charges / overall_damage
	if(victim == caster)
		to_chat(caster, span_cultboldtalic("Your blood healing is far less efficient when used on yourself!"))
		ratio *= 0.35 // Healing is half as effective if you can't perform a full heal
		charge_tracker.charges -= round(overall_damage) // Healing is 65% more "expensive" even if you can still perform the full heal

	if(ratio > 1)
		ratio = 1
		charge_tracker.charges -= round(overall_damage)
		victim.visible_message(
			span_warning("[victim] is fully healed by [victim == caster ? "[victim.p_their()]" : "[caster]'s"] blood magic!"),
			span_danger("You are fully healed by [victim == caster ? "your" : "[caster]'s"] blood magic!"),
		)
	else
		victim.visible_message(
			span_warning("[victim] is partially healed by [victim == caster ? "[victim.p_their()]":"[caster]'s"] blood magic."),
			span_danger("You are partially healed by [victim == caster ? "your" : "[caster]'s"] blood magic."),
		)
		charge_tracker.charges = 0

	ratio *= -1
	victim.adjustOxyLoss(overall_damage * ratio * (victim.getOxyLoss() / overall_damage), FALSE)
	victim.adjustToxLoss(overall_damage * ratio * (victim.getToxLoss() / overall_damage), FALSE)
	victim.adjustFireLoss(overall_damage * ratio * (victim.getFireLoss() / overall_damage), FALSE)
	victim.adjustBruteLoss(overall_damage * ratio * (victim.getBruteLoss() / overall_damage), FALSE)
	victim.updatehealth()
	playsound(victim, 'sound/magic/staff_healing.ogg', 25)
	new /obj/effect/temp_visual/cult/sparks(get_turf(victim))
	if(caster != victim)
		caster.Beam(victim, icon_state = "sendbeam", time = 1.5 SECONDS)
	return TRUE

/datum/action/cooldown/spell/touch/blood_rites/proc/drain_victim(mob/living/carbon/human/victim, mob/living/carbon/caster)
	if(victim.stat == DEAD)
		victim.balloon_alert(caster, "blood isn't flowing, they're dead!")
		return FALSE
	if(victim.has_status_effect(/datum/status_effect/speech/slurring/cult))
		victim.balloon_alert(caster, "tainted by stronger magic!")
		return FALSE
	if(victim.blood_volume <= BLOOD_VOLUME_SAFE)
		victim.balloon_alert(caster, "blood is too low!")
		return FALSE

	victim.blood_volume -= human_drain_amount
	charge_tracker.charges += (human_drain_amount / 2)
	build_all_button_icons(UPDATE_BUTTON_NAME)
	caster.Beam(victim, icon_state = "drainbeam", time = 1 SECONDS)

	playsound(victim, 'sound/magic/enter_blood.ogg', 50)
	victim.visible_message(
		span_danger("[caster] drains some of [victim]'s blood!"),
		span_userdanger("You feel your blood being drained away by [caster]'s magic!"),
	)
	to_chat(caster, span_cultitalic("Your blood rite gains [human_drain_amount / 2] charges from draining [victim]'s blood."))
	new /obj/effect/temp_visual/cult/sparks(get_turf(victim))

	return null // This shouldn't have a return value so the hand doesn't go away after casting.

/datum/action/cooldown/spell/touch/blood_rites/proc/absorb_blood(obj/effect/decal/cleanable/blood/target, mob/living/carbon/caster)
	var/total_blood = 0
	var/turf/target_turf = get_turf(target)
	if(isnull(target_turf))
		CRASH("[type] absorb_blood somehow got a blood decal in nullspace.")

	for(var/obj/effect/decal/cleanable/blood/close_blood in view(target_turf, 2))
		if(close_blood.blood_state != BLOOD_STATE_HUMAN)
			continue

		if(close_blood.bloodiness == 100) //Bonus for "pristine" bloodpools, also to prevent cheese with footprint spam
			total_blood += 30
		else
			total_blood += max((close_blood.bloodiness ** 2) / 800, 1)

		new /obj/effect/temp_visual/cult/turf/floor(get_turf(close_blood))
		qdel(close_blood)

	for(var/obj/effect/decal/cleanable/trail_holder/trail in view(target_turf, 2))
		qdel(trail)

	total_blood = round(total_blood)
	if(!total_blood)
		return

	caster.Beam(target_turf, icon_state="drainbeam", time = 1.5 SECONDS)
	new /obj/effect/temp_visual/cult/sparks(get_turf(caster))
	playsound(target_turf, 'sound/magic/enter_blood.ogg', 50)
	target.balloon_alert(caster, "[total_blood] charge\s gained")
	charge_tracker.charges += max(1, total_blood)
	build_all_button_icons(UPDATE_BUTTON_NAME)

	return null // This shouldn't have a return value so the hand doesn't go away after casting.

/obj/item/melee/touch_attack/cult/manipulator
	name = "blood rite"
	desc = "Absorbs blood from anything you touch. \
		Touching cultists and constructs can heal them. \
		Use in-hand to cast an advanced rite."
	color = "#7D1717"

#undef BLOOD_HALBERD_COST
#undef BLOOD_BARRAGE_COST
#undef BLOOD_BEAM_COST

#undef BLOOD_HALBERD_KEY
#undef BLOOD_BARRAGE_KEY
#undef BLOOD_BEAM_KEY
