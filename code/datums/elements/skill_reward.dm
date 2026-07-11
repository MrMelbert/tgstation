///An element that forbids mobs without a required skill level from equipping the item.
/datum/element/skill_reward
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	///The required skill the user has to have to equip the item.
	var/associated_skill

/datum/element/skill_reward/Attach(datum/target, associated_skill)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE

	src.associated_skill = associated_skill
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(target, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand))
	RegisterSignal(target, COMSIG_ITEM_MOB_CAN_EQUIP, PROC_REF(block_equip))

/datum/element/skill_reward/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ATOM_EXAMINE, COMSIG_ATOM_ATTACK_HAND, COMSIG_ITEM_MOB_CAN_EQUIP))

/datum/element/skill_reward/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("You notice a powerful aura about this item, suggesting that only the truly experienced may wield it.")

/datum/element/skill_reward/proc/on_attack_hand(datum/source, mob/living/user, list/modifiers)
	SIGNAL_HANDLER
	if(!LAZYACCESS(modifiers, CTRL_CLICK) && !check_equippable(user)) //Allows other players to drag it around at least.
		to_chat(user, span_warning("You feel completely and utterly unworthy to even touch \the [source]."))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	return NONE

///We check if the item can be equipped, otherwise we drop it.
/datum/element/skill_reward/proc/block_equip(datum/source, mob/living/user, slot, disable_warning, ignore_equipped)
	SIGNAL_HANDLER
	if(check_equippable(user))
		return NONE
	if(!disable_warning)
		to_chat(user, span_warning("You feel completely and utterly unworthy to even touch \the [source]."))
	return BLOCK_ITEM_EQUIP

/datum/element/skill_reward/proc/check_equippable(mob/living/user)
	return user.mind?.get_skill_level(associated_skill) >= SKILL_LEVEL_LEGENDARY

/**
 * Welp, the code is pretty much the same, except for one tiny detail, I suppose it's ok to make a subtype of this element.
 * That tiny detail is that we don't check for skills, but if the player has played for thousands of hours.
 */
/datum/element/skill_reward/veteran
	element_flags = NONE

/datum/element/skill_reward/veteran/check_equippable(mob/user)
	return user.client?.is_veteran()
