/// Signal handler for [COMSIG_SIGNLANGUAGE_ENABLE]
/// Enables signing for the parent Carbon, stopping them from speaking vocally.
/// This proc is only called directly after TRAIT_SIGN_LANG is added to the Carbon.
/datum/component/sign_language/proc/enable_sign_language()
	SIGNAL_HANDLER

	carbon_parent.bubble_icon = "signlang"
	return TRUE

/datum/component/wearertargeting/allow_radio_signing
	signals = list(COMSIG_MOVABLE_USING_RADIO)
	proctype = PROC_REF(radio_help)

/datum/component/wearertargeting/allow_radio_signing/Initialize()
	. = ..()
	valid_slots = astype(parent, /obj/item)?.slot_flags || NONE

/datum/component/wearertargeting/allow_radio_signing/proc/radio_help(...)
	SIGNAL_HANDLER
	return COMPONENT_ALLOW_VISUAL_RADIO
