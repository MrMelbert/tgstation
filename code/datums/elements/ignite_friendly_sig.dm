/// You can click on a friendly mob to try to light their cigarette
/datum/element/ignite_friendly_sig

/datum/element/ignite_friendly_sig/Attach(datum/target)
	. = ..()
	RegisterSignal(target, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(on_item_interaction))

/datum/element/ignite_friendly_sig/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, COMSIG_ITEM_INTERACTING_WITH_ATOM)

/datum/element/ignite_friendly_sig/proc/on_item_interaction(obj/item/source, mob/living/user, atom/target, ...)
	SIGNAL_HANDLER

	if(!isliving(target) || user.combat_mode || !source.get_temperature())
		return NONE

	var/mob/living/friend = target
	var/obj/item/cigarette/cig = friend.get_item_by_slot(ITEM_SLOT_MASK)
	if(!istype(cig))
		return NONE

	if(cig.lit)
		friend.balloon_alert(user, "already lit!")
		return ITEM_INTERACT_BLOCKING

	if(!cig.check_oxygen(friend))
		friend.balloon_alert(user, "no air!")
		return ITEM_INTERACT_BLOCKING

	var/lighting_text = user == friend ? source.ignition_effect(cig, user) : source.worn_item_ignition_effect(cig, friend, user)
	if(!lighting_text)
		return ITEM_INTERACT_BLOCKING

	cig.try_light(user, lighting_text)
	return ITEM_INTERACT_SUCCESS
