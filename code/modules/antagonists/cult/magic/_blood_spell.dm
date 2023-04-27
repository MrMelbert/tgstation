/**
 * Simple spell action component that transforms it from a cooldown-based system to a charge based system.
 */
/datum/component/charge_spell
	/// The decription of the blood spell unmodified, used for updating with charges remaining
	VAR_FINAL/base_desc

	/// How many charges we have currently
	var/charges = 1
	/// How many charges is used per cast
	var/per_cast_cost = 1

/datum/component/charge_spell/Initialize(charges = 1, per_cast_cost = 1)
	if(!istype(parent, /datum/action/cooldown/spell))
		return COMPONENT_INCOMPATIBLE

	var/datum/action/cooldown/spell/real_parent = parent

	src.charges = charges
	src.per_cast_cost = per_cast_cost
	src.base_desc = real_parent.desc

	real_parent.cooldown_time = 0 SECONDS

/datum/component/charge_spell/RegisterWithParent()
	RegisterSignal(parent, COMSIG_SPELL_ADMIN_GRANTED, PROC_REF(on_admin_grant))
	RegisterSignal(parent, COMSIG_SPELL_AFTER_CAST, PROC_REF(after_spell_cast))
	RegisterSignal(parent, COMSIG_ACTION_BUTTON_NAME_UPDATE, PROC_REF(update_description))
	RegisterSignal(parent, COMSIG_SPELL_CAST_RESET, PROC_REF(reset_charge))

	var/datum/action/cooldown/spell/real_parent = parent
	real_parent.build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/component/charge_spell/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_SPELL_AFTER_CAST, COMSIG_ACTION_BUTTON_NAME_UPDATE, COMSIG_SPELL_CAST_RESET, COMSIG_SPELL_ADMIN_GRANTED))

/datum/component/charge_spell/proc/on_admin_grant(datum/action/cooldown/spell/source, mob/recipient, mob/admin)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(admin_setup), source, recipient, admin)

/datum/component/charge_spell/proc/admin_setup(datum/action/cooldown/spell/source, mob/recipient, mob/admin)
	var/edit_charges = tgui_input_number(admin, "This spell is a charge spell by default. \
		Edit charges (or make it infinite)?", "Charge spell", charges, INFINITY, 1)
	if(!isnum(edit_charges) || QDELETED(src) || QDELETED(source))
		return
	if(!check_rights_for(admin.client, NONE))
		return

	charges = edit_charges

/// Signal proc for [COMSIG_SPELL_AFTER_CAST].
/// After cast, consume a charge. If no charges remain, delete the parent.
/datum/component/charge_spell/proc/after_spell_cast(datum/action/cooldown/spell/source)
	SIGNAL_HANDLER

	charges -= per_cast_cost
	if(charges <= 0)
		// This can later be expanded with the option to regenerate over time
		// rather than self-delete. But someone else can do that.
		qdel(parent)
		return

	source.build_all_button_icons(UPDATE_BUTTON_NAME)

/// Signal proc for [COMSIG_ACTION_BUTTON_NAME_UPDATE].
/// Update our button description with the number of charges remaining.
/datum/component/charge_spell/proc/update_description(datum/action/cooldown/spell/source, atom/movable/screen/movable/action_button/button, force = FALSE)
	SIGNAL_HANDLER

	button.desc = "[base_desc]<br><b><u>Has [charges] use\s remaining</u></b>."

/// Signal proc for [COMSIG_SPELL_CAST_RESET].
/// If we get reset, give us our charges back. (Unfortunately you can't reset it, if it's been deleted.)
/datum/component/charge_spell/proc/reset_charge(datum/action/cooldown/spell/source)
	SIGNAL_HANDLER

	// charges += per_cast_cost
	// source.build_all_button_icons(UPDATE_BUTTON_NAME)

/**
 * Subtype of the charge spell component (I know) that turns puts a culty twist on it.
 *
 * When a charge is depleted, we will also apply damage to the caster's active hand
 */
/datum/component/charge_spell/blood_cost
	/// How much brute damage is applied when a charge is spent / the spell is cast?
	var/health_cost = 5

/datum/component/charge_spell/blood_cost/Initialize(charges = 1, per_cast_cost = 1, health_cost = 5)
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return

	src.health_cost = health_cost

/datum/component/charge_spell/blood_cost/after_spell_cast(datum/action/cooldown/spell/source)
	if(isliving(source.owner) && health_cost)
		var/mob/living/caster = source.owner
		var/lefthand_cast = (caster.active_hand_index % 2 == 0)
		caster.apply_damage(health_cost, BRUTE, lefthand_cast ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM, wound_bonus = CANT_WOUND)

	return ..()

/// Simple element that makes a spell sanity checks the caster is a cultist in before_cast.
/datum/element/cult_spell

/datum/element/cult_spell/Attach(datum/target)
	. = ..()
	if(!istype(target, /datum/action/cooldown/spell))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_SPELL_BEFORE_CAST, PROC_REF(on_spell_cast))

/datum/element/cult_spell/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_SPELL_BEFORE_CAST)

/datum/element/cult_spell/proc/on_spell_cast(datum/action/cooldown/spell/source, atom/cast_on)
	SIGNAL_HANDLER

	if(!IS_CULTIST(source.owner))
		return SPELL_CANCEL_CAST
