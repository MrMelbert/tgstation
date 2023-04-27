/datum/action/cooldown/spell/summonitem/cult_halberd
	name = "Bloody Bond"
	desc = "Call the bloody halberd back to your hand!"
	DEFINE_CULT_ACTION("bloodspear", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation_type = INVOCATION_NONE
	cooldown_time = 2 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	default_button_position = DEFAULT_UNIQUE_BLOODSPELLS

/datum/action/cooldown/spell/summonitem/cult_halberd/try_link_item(mob/living/caster)
	return // Nope

/datum/action/cooldown/spell/summonitem/cult_halberd/try_unlink_item(mob/living/caster)
	return // Nope

/datum/action/cooldown/spell/summonitem/cult_halberd/unmark_item()
	. = ..()
	qdel(src) // Halberd is gone, we are gone

/datum/action/cooldown/spell/summonitem/cult_halberd/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	if(QDELETED(marked_item))
		return FALSE

	if(get_dist(get_turf(owner), get_turf(marked_item)) > 10)
		if(feedback)
			owner.balloon_alert(owner, "too far away!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/summonitem/cult_halberd/try_recall_item(mob/living/caster)
	var/is_in_view = (caster in view(get_turf(marked_item)))

	if(isliving(marked_item.loc))
		var/mob/living/current_owner = marked_item.loc
		current_owner.dropItemToGround(marked_item)
		current_owner.visible_message(span_warning("An unseen force pulls [marked_item] from [current_owner]'s hands[is_in_view ? " towards [caster]" : ""]!"))
	else if(!isturf(marked_item.loc))
		to_chat(caster, span_warning("Try as you might, but your [marked_item.name] will not heed your call!"))
		return
	else
		marked_item.visible_message(span_warning("An unseen force sends [marked_item] flying[is_in_view ? " towards [caster]" : ""]!"))

	marked_item.throw_at(caster, 10, 2, caster)

// The halberd itself
/obj/item/melee/cultblade/halberd
	name = "bloody halberd"
	desc = "A halberd with a volatile axehead made from crystallized blood. It seems linked to its creator. \
		And, admittedly, more of a poleaxe than a halberd."
	icon = 'icons/obj/cult/items_and_weapons.dmi'
	icon_state = "occultpoleaxe0"
	base_icon_state = "occultpoleaxe"
	inhand_icon_state = "occultpoleaxe0"
	w_class = WEIGHT_CLASS_HUGE
	force = 17
	throwforce = 40
	throw_speed = 2
	armour_penetration = 30
	block_chance = 30
	slot_flags = null
	attack_verb_continuous = list("attacks", "slices", "shreds", "sunders", "lacerates", "cleaves")
	attack_verb_simple = list("attack", "slice", "shred", "sunder", "lacerate", "cleave")
	sharpness = SHARP_EDGED
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/melee/cultblade/halberd/Initialize(mapload)
	. = ..()
	AddComponent(
		/datum/component/butchering, \
		speed = 10 SECONDS, \
		effectiveness = 90, \
	)
	AddComponent(
		/datum/component/two_handed, \
		force_unwielded = 17, \
		force_wielded = 24, \
	)

/obj/item/melee/cultblade/halberd/update_icon_state()
	icon_state = HAS_TRAIT(src, TRAIT_WIELDED) ? "[base_icon_state]1" : "[base_icon_state]0"
	inhand_icon_state = HAS_TRAIT(src, TRAIT_WIELDED) ? "[base_icon_state]1" : "[base_icon_state]0"
	return ..()

/obj/item/melee/cultblade/halberd/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!isliving(hit_atom))
		return ..()

	var/turf/hit_turf = get_turf(hit_atom)
	var/mob/living/target = hit_atom
	if(IS_CULTIST(target) && target.put_in_active_hand(src))
		playsound(src, 'sound/weapons/throwtap.ogg', 50)
		target.visible_message(span_warning("[target] catches [src] out of the air!"))
		return TRUE
	if(target.can_block_magic() || IS_CULTIST(target))
		target.visible_message(span_warning("[src] bounces off of [target], as if repelled by an unseen force!"))
		return TRUE
	. = ..()
	if(!.)
		target.Paralyze(5 SECONDS)
		break_halberd(hit_turf)

/obj/item/melee/cultblade/halberd/proc/break_halberd(turf/landing_turf)
	if(QDELETED(src))
		return

	landing_turf ||= get_turf(src)
	if(!isnull(landing_turf))
		landing_turf.visible_message(span_warning("[src] shatters and melts back into blood!"))
		new /obj/effect/temp_visual/cult/sparks(landing_turf)
		new /obj/effect/decal/cleanable/blood/splatter(landing_turf)
		playsound(landing_turf, 'sound/effects/glassbr3.ogg', 100)
	qdel(src)

/obj/item/melee/cultblade/halberd/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(HAS_TRAIT(src, TRAIT_WIELDED))
		final_block_chance *= 2
	if(!IS_CULTIST(owner) || !prob(final_block_chance))
		return FALSE

	if(attack_type == PROJECTILE_ATTACK)
		owner.visible_message(span_danger("[owner] deflects [attack_text] with [src]!"))
		playsound(get_turf(owner), pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 75, TRUE)
	else
		owner.visible_message(span_danger("[owner] parries [attack_text] with [src]!"))
		playsound(src, 'sound/weapons/parry.ogg', 100, TRUE)

	new /obj/effect/temp_visual/cult/sparks(get_turf(owner))
	return TRUE
