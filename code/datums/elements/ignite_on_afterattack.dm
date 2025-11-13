/// After hitting a mob, sets them on fire if they have firestacks + makes the environment a bit hot (setting off plasmafires)
/datum/element/ignite_on_afterattack

/datum/element/ignite_on_afterattack/Attach(datum/target)
	. = ..()
	RegisterSignal(target, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/element/ignite_on_afterattack/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, COMSIG_ITEM_AFTERATTACK)

/datum/element/ignite_on_afterattack/proc/on_afterattack(obj/item/source, mob/living/user, atom/target, list/modifiers)
	SIGNAL_HANDLER

	if(!isliving(target) || QDELETED(target))
		return

	var/weapon_temp = source.get_temperature()
	if(weapon_temp <= 0)
		return

	var/mob/living/victim = target
	if(victim.ignite_mob())
		message_admins("[ADMIN_LOOKUPFLW(user)] set [key_name_admin(victim)] on fire with [source] at [AREACOORD(user)]")
		user.log_message("set [key_name(victim)] on fire with [source]", LOG_ATTACK)

	var/turf/location = get_turf(user)
	location.hotspot_expose(weapon_temp / 5, 50, 1)
