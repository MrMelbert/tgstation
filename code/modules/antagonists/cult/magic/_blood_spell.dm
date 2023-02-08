/datum/component/blood_spell
	var/charges = 1
	var/health_cost = 0
	var/base_desc

/datum/component/blood_spell/Initialize(charges = 1, health_cost = 0)
	if(!istype(parent, /datum/action/cooldown/spell))
		return COMPONENT_INCOMPATIBLE

	var/datum/action/cooldown/spell/real_parent = parent
	src.charges = charges
	src.health_cost = health_cost
	src.base_desc = real_parent.desc

/datum/component/blood_spell/RegisterWithParent()
	RegisterSignal(parent, COMSIG_SPELL_AFTER_CAST, PROC_REF(after_spell_cast))
	RegisterSignal(parent, COMSIG_ACTION_BUTTON_NAME_UPDATE, PROC_REF(update_description))

	var/datum/action/cooldown/spell/real_parent = parent
	real_parent.build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/component/blood_spell/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_SPELL_AFTER_CAST, COMSIG_ACTION_BUTTON_NAME_UPDATE))

/datum/component/blood_spell/proc/after_spell_cast(datum/action/cooldown/spell/source)
	SIGNAL_HANDLER

	if(isliving(source.owner) && health_cost)
		var/mob/living/caster = source.owner
		var/lefthand_cast = (caster.active_hand_index % 2 == 0)
		caster.apply_damage(health_cost, BRUTE, lefthand_cast ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM, wound_bonus = CANT_WOUND)

	charges--
	if(charges <= 0)
		qdel(parent)
		return

	source.build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/component/blood_spell/proc/update_description(datum/action/cooldown/spell/source, atom/movable/screen/movable/action_button/button, force = FALSE)
	SIGNAL_HANDLER

	button.desc = "[base_desc]<br><b><u>Has [charges] use\s remaining</u></b>."
