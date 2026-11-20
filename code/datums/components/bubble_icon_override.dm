/**
 * A component that overrides the bubble_icon variable when equipped or implanted
 * while having a simple priority system, so accessories have higher priority than
 * organs, for example.
 */
/datum/component/bubble_icon_override
	dupe_mode = COMPONENT_DUPE_ALLOWED
	can_transfer = TRUE //sure why not
	///The override to the default bubble icon for the atom
	var/bubble_icon
	///The priority of this bubble icon compared to others
	var/priority

/datum/component/bubble_icon_override/Initialize(bubble_icon, priority)
	if(!isclothing(parent) && !isorgan(parent))
		return COMPONENT_INCOMPATIBLE
	src.bubble_icon = bubble_icon
	src.priority = priority

/datum/component/bubble_icon_override/RegisterWithParent()
	if(isclothing(parent))
		RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))
	else if(isorgan(parent))
		RegisterSignal(parent, COMSIG_ORGAN_IMPLANTED, PROC_REF(on_organ_implanted))
		RegisterSignal(parent, COMSIG_ORGAN_REMOVED, PROC_REF(on_organ_removed))
	var/mob/living/target = get_bubble_icon_target()
	if(target)
		register_owner(target)

/datum/component/bubble_icon_override/proc/register_owner(mob/living/owner)
	RegisterSignal(owner, COMSIG_LIVING_UPDATE_BUBBLE_ICON, PROC_REF(give_bubble_icon))
	owner.update_bubble_icon()

/datum/component/bubble_icon_override/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ITEM_EQUIPPED,
		COMSIG_ITEM_DROPPED,
		COMSIG_ORGAN_IMPLANTED,
		COMSIG_ORGAN_REMOVED,
	))
	var/mob/living/target = get_bubble_icon_target()
	if(target)
		unregister_owner(target)

/datum/component/bubble_icon_override/proc/unregister_owner(mob/living/owner)
	UnregisterSignal(owner, COMSIG_LIVING_UPDATE_BUBBLE_ICON)
	owner.update_bubble_icon()

///Returns the potential wearer/owner of the object when the component is un/registered to/from it
/datum/component/bubble_icon_override/proc/get_bubble_icon_target()
	if(isclothing(parent))
		var/obj/item/clothing/clothing = parent
		if(istype(clothing, /obj/item/clothing/accessory))
			clothing = clothing.loc
			if(!istype(clothing))
				return null
		var/mob/living/wearer = clothing.loc
		if(istype(wearer) && (wearer.get_slot_by_item(clothing) & clothing.slot_flags))
			return parent
	else if(isorgan(parent))
		var/obj/item/organ/organ = parent
		return organ.owner
	return null

/datum/component/bubble_icon_override/proc/on_equipped(obj/item/source, mob/equipper, slot)
	SIGNAL_HANDLER
	if(slot & source.slot_flags)
		register_owner(equipper)

/datum/component/bubble_icon_override/proc/on_dropped(obj/item/source, mob/dropper)
	SIGNAL_HANDLER
	unregister_owner(dropper)

/datum/component/bubble_icon_override/proc/on_organ_implanted(obj/item/organ/source, mob/owner)
	SIGNAL_HANDLER
	register_owner(owner)

/datum/component/bubble_icon_override/proc/on_organ_removed(obj/item/organ/source, mob/owner)
	SIGNAL_HANDLER
	unregister_owner(owner)

/datum/component/bubble_icon_override/proc/give_bubble_icon(datum/source, list/bubble_icons)
	SIGNAL_HANDLER
	bubble_icons[bubble_icon] = max(priority, bubble_icons[bubble_icon] || 0)
