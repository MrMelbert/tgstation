/// Lightweight component to add a special effect when the parent item lands a finishing blow on a mob
/datum/component/on_finishing_blow
	/// Callback to invoke when a finishing blow is landed
	var/datum/callback/finishing_attack
	/// Status the target mob must reach for the finishing blow to trigger
	var/finishing_stat = DEAD

/datum/component/on_finishing_blow/Initialize(datum/callback/finishing_attack, finishing_stat)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	if(isnull(finishing_attack))
		return COMPONENT_INCOMPATIBLE

	src.finishing_attack = finishing_attack
	src.finishing_stat = finishing_stat

/datum/component/on_finishing_blow/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_PRE_ATTACK, PROC_REF(track_stat))
	RegisterSignal(parent, COMSIG_ITEM_AFTERATTACK, PROC_REF(check_finishing_blow))

/datum/component/on_finishing_blow/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_PRE_ATTACK)
	UnregisterSignal(parent, COMSIG_ITEM_AFTERATTACK)

#define PRE_STAT_KEY "pre_stat"

/datum/component/on_finishing_blow/proc/track_stat(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER

	if(!isliving(target))
		return

	var/mob/living/living_target = target
	LAZYSET(attack_modifiers, PRE_STAT_KEY, living_target.stat)

/datum/component/on_finishing_blow/proc/check_finishing_blow(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER

	if(!isliving(target))
		return

	var/mob/living/living_target = target
	var/pre_stat = LAZYACCESS(attack_modifiers, PRE_STAT_KEY)
	if(living_target.stat >= finishing_stat && pre_stat < finishing_stat)
		finishing_attack.Invoke(target, user)

#undef PRE_STAT_KEY
