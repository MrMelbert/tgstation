/datum/action/cooldown/spell/touch/cult_armor
	name = "Summon Combat Equipment"
	desc = "Will equip cult combat gear onto a cultist on contact."
	DEFINE_CULT_ACTION("equip", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	hand_path = /obj/item/melee/touch_attack/cult/armor
	can_cast_on_self = TRUE

/datum/action/cooldown/spell/touch/cult_armor/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell, charges = 1)

/datum/action/cooldown/spell/touch/cult_armor/is_valid_target(atom/cast_on)
	var/mob/living/carbon/carbon_cast_on = cast_on
	return istype(carbon_cast_on) && IS_CULTIST(carbon_cast_on)

/datum/action/cooldown/spell/touch/cult_armor/cast_on_hand_hit(obj/item/melee/touch_attack/hand, mob/living/carbon/victim, mob/living/carbon/caster)
	to_chat(caster, span_notice("You equip [caster == victim ? "yourself" : victim] with an assortment of equipment."))
	victim.visible_message(
		span_warning("Otherworldly armor suddenly appears on [victim]!"),
		span_notice("A set of otherworldly armor envelops you."),
	)
	victim.equip_to_slot_or_del(new /obj/item/clothing/under/color/black(victim), ITEM_SLOT_ICLOTHING)
	victim.equip_to_slot_or_del(new /obj/item/clothing/suit/hooded/cultrobes/alt(victim), ITEM_SLOT_OCLOTHING)
	victim.equip_to_slot_or_del(new /obj/item/clothing/shoes/cult/alt(victim), ITEM_SLOT_FEET)
	victim.equip_to_slot_or_del(new /obj/item/storage/backpack/cultpack(victim), ITEM_SLOT_BACK)
	return TRUE

/datum/action/cooldown/spell/touch/cult_armor/after_cast(mob/living/carbon/cast_on)
	. = ..()
	// This part is done in after cast, as we need for the hand to go away before giving these out.
	cast_on.put_in_hands(new /obj/item/melee/cultblade/dagger(cast_on.loc))
	cast_on.put_in_hands(new /obj/item/restraints/legcuffs/bola/cult(cast_on.loc))

/obj/item/melee/touch_attack/cult/armor
	name = "arming aura"
	desc = "Will equip cult combat gear onto a cultist on contact."
	color = "#33cc33"
