//adds godmode while in the container, prevents moving, and clears these effects up after leaving the stone
/datum/component/soulstoned
	var/atom/movable/container

/datum/component/soulstoned/Initialize(atom/movable/container)
	if(!isanimal(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/simple_animal/shade = parent

	src.container = container

	shade.fully_heal()

/datum/component/soulstoned/RegisterWithParent()
	var/mob/living/simple_animal/shade = parent

	RegisterSignal(shade, COMSIG_MOVABLE_MOVED, .proc/free_prisoner)
	RegisterSignal(parent, COMSIG_ATOM_RELAYMOVE, .proc/block_buckle_message)
	RegisterSignal(shade, COMSIG_LIVING_SUICIDE_CHECK, .proc/on_suicide_check)
	ADD_TRAIT(shade, TRAIT_IMMOBILIZED, SOULSTONE_TRAIT)
	ADD_TRAIT(shade, TRAIT_HANDS_BLOCKED, SOULSTONE_TRAIT)
	shade.status_flags |= GODMODE

/datum/component/soulstoned/UnregisterFromParent()
	var/mob/living/simple_animal/shade = parent

	UnregisterSignal(shade, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_RELAYMOVE, COMSIG_LIVING_SUICIDE_CHECK))
	REMOVE_TRAIT(shade, TRAIT_IMMOBILIZED, SOULSTONE_TRAIT)
	ADD_TRAIT(shade, TRAIT_HANDS_BLOCKED, SOULSTONE_TRAIT)
	shade.status_flags &= ~GODMODE

/datum/component/soulstoned/proc/free_prisoner(datum/source)
	SIGNAL_HANDLER

	var/mob/living/simple_animal/shade = parent
	if(shade.loc == container)
		return

	qdel(src)

///signal fired from a mob moving inside the parent
/datum/component/soulstoned/proc/block_buckle_message(datum/source)
	SIGNAL_HANDLER

	return COMSIG_BLOCK_RELAYMOVE

/datum/component/soulstoned/proc/on_suicide_check(datum/source)
	SIGNAL_HANDLER

	return COMPONENT_BLOCK_SUICIDE
