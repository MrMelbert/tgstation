/**
 * ## Godmode Container
 *
 * Any living mobs which enters our atom gains godmode and can no longer move. Also block the suicide verb.
 * Exiting the atom will remove the godmode and allow them to move once again
 */
/datum/element/godmode_container

/datum/element/godmode_container/Attach(datum/target)
	. = ..()
	if(!atom(target))
		return ELEMENT_INCOMPATIBLE

/datum/element/godmode_container/RegisterWithParent()
	RegisterSignals(parent, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_INITIALIZED_ON), PROC_REF(on_enter))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(on_exit))

/datum/element/godmode_container/UnregisterFromParent()
	UnregisterSignal(shade, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))

/**
 * Signal proc for [COMSIG_ATOM_ENTERED] and [COMSIG_ATOM_INITIALIZED_ON]
 *
 * Any living mob that enters our atom gains godmode and can no longer move / act
 */
/datum/element/godmode_container/proc/on_enter(atom/movable/source, mob/living/arrived)
	SIGNAL_HANDLER

	if(!istype(arrived))
		return

	arrived.fully_heal()
	RegisterSignal(arrived, COMSIG_ATOM_RELAYMOVE, PROC_REF(block_buckle_message))
	RegisterSignal(arrived, COMSIG_LIVING_SUICIDE_CHECK, PROC_REF(on_suicide_check))
	ADD_TRAIT(arrived, TRAIT_IMMOBILIZED, REF(src))
	ADD_TRAIT(arrived, TRAIT_HANDS_BLOCKED, REF(src))
	arrived.status_flags |= GODMODE

/**
 * Signal proc for [COMSIG_ATOM_EXITED]
 *
 * Exiting the atom removes our godmode and stuff
 */
/datum/element/godmode_container/proc/on_exit(atom/movable/source, mob/living/exiting)
	SIGNAL_HANDLER

	if(!istype(exiting))
		return

	UnregisterSignal(exiting, list(COMSIG_ATOM_RELAYMOVE, COMSIG_LIVING_SUICIDE_CHECK))
	REMOVE_TRAIT(exiting, TRAIT_IMMOBILIZED, SOULSTONE_TRAIT)
	REMOVE_TRAIT(exiting, TRAIT_HANDS_BLOCKED, SOULSTONE_TRAIT)
	exiting.status_flags &= ~GODMODE

/// [COMSIG_ATOM_RELAYMOVE] registered onto any inhabitants. Blocks the "you're buckled mate" message.
/datum/element/godmode_container/proc/block_buckle_message(datum/source)
	SIGNAL_HANDLER

	return COMSIG_BLOCK_RELAYMOVE

/// [COMSIG_LIVING_SUICIDE_CHECK] registered onto any inhabitants. Stops suicide acting
/datum/element/godmode_container/proc/on_suicide_check(datum/source)
	SIGNAL_HANDLER

	return COMPONENT_BLOCK_SUICIDE
