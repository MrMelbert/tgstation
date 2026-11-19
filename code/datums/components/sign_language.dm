/datum/component/wearertargeting/allow_radio_signing
	signals = list(COMSIG_MOVABLE_USING_RADIO)
	proctype = PROC_REF(radio_help)

/datum/component/wearertargeting/allow_radio_signing/Initialize()
	. = ..()
	valid_slots = astype(parent, /obj/item)?.slot_flags || NONE

/datum/component/wearertargeting/allow_radio_signing/proc/radio_help(...)
	SIGNAL_HANDLER
	return COMPONENT_ALLOW_VISUAL_RADIO
