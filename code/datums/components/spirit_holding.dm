/**
 * spirit holding component; for items to have spirits inside of them for "advice"
 *
 * Used for the possessed blade and fantasy affixes
 */
/datum/component/spirit_holding
	/// What's the spirit's name?
	var/spirit_name
	///bool on if this component is currently polling for observers to inhabit the item
	var/attempting_awakening = FALSE
	///mob contained in the item.
	var/mob/living/simple_animal/shade/bound_spirit

/datum/component/spirit_holding/Initialize()
	if(!ismovable(parent)) //you may apply this to mobs, i take no responsibility for how that works out
		return COMPONENT_INCOMPATIBLE

	// two-fer-one component deal - buy one get one free
	parent.AddComponent(/datum/component/exorcisable, \
		pre_exorcism_callback = CALLBACK(src, .proc/pre_exorcism), \
		on_exorcism_callback = CALLBACK(src, .proc/on_exorcism))

/datum/component/spirit_holding/Destroy(force, silent)
	QDEL_NULL(bound_spirit)
	return ..()

/datum/component/spirit_holding/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/on_examine)
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, .proc/on_attack_self)
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, .proc/on_destroy)
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_NAME, .proc/on_update_name)

/datum/component/spirit_holding/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_ITEM_ATTACK_SELF, COMSIG_PARENT_QDELETING, COMSIG_ATOM_UPDATE_NAME))

///signal fired on examining the parent
/datum/component/spirit_holding/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!bound_spirit)
		examine_list += span_notice("[parent] sleeps. Use [parent] in your hands to attempt to awaken it.")
		return
	examine_list += span_notice("[parent] is alive.")

///signal fired on self attacking parent
/datum/component/spirit_holding/proc/on_attack_self(datum/source, mob/user)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, .proc/attempt_spirit_awaken, user)

/**
 * attempt_spirit_awaken: called from on_attack_self, polls ghosts to possess the item in the form
 * of a mob sitting inside the item itself
 *
 * Arguments:
 * * awakener: user who interacted with the blade
 */
/datum/component/spirit_holding/proc/attempt_spirit_awaken(mob/awakener)
	if(attempting_awakening)
		to_chat(awakener, span_warning("You are already trying to awaken [parent]!"))
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		to_chat(awakener, span_warning("Anomalous otherworldly energies block you from awakening [parent]!"))
		return

	attempting_awakening = TRUE
	to_chat(awakener, span_notice("You attempt to wake the spirit of [parent]..."))

	var/mob/dead/observer/candidates = poll_ghost_candidates("Do you want to play as the spirit of [awakener.real_name]'s blade?", ROLE_PAI, FALSE, 100, POLL_IGNORE_POSSESSED_BLADE)
	if(!LAZYLEN(candidates))
		to_chat(awakener, span_warning("[parent] is dormant. Maybe you can try again later."))
		attempting_awakening = FALSE
		return

	//Immediately unregister to prevent making a new spirit
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_SELF)

	var/atom/movable/movable_parent = parent
	var/mob/dead/observer/chosen_spirit = pick(candidates)
	bound_spirit = new(parent)
	// Put the candidate incontrol
	bound_spirit.ckey = chosen_spirit.ckey
	// Give them a name
	bound_spirit.fully_replace_character_name(null, "The spirit of [parent]")
	// Make sure the sword can understand and communicate with the awakener.
	bound_spirit.copy_languages(awakener, LANGUAGE_MASTER)
	bound_spirit.update_atom_languages()
	// Also give them omnitingue so they can speak it
	bound_spirit.grant_all_languages(FALSE, FALSE, TRUE)
	// Give them soulstone component (godmode, inability to move, etc)
	bound_spirit.AddComponent(/datum/component/soulstoned, parent)

	var/input = sanitize_name(tgui_input_text(bound_spirit, "What are you named?", "Spectral Nomenclature", max_length = MAX_NAME_LEN))
	if(input)
		spirit_name = input
		bound_spirit.fully_replace_character_name(null, "The spirit of [input]")

	movable_parent.update_name()
	attempting_awakening = FALSE

/datum/component/spirit_holding/proc/pre_exorcism(mob/living/exorcist)
	if(!bound_spirit)
		return STOP_EXORCISM

/datum/component/spirit_holding/proc/on_exorcism(mob/living/exorcist)
	if(!bound_spirit) // Spirit died sometime during the exorcism, shrug
		return FALSE

	to_chat(bound_spirit, span_userdanger("You were exorcised!"))
	exorcist.visible_message(span_notice("[exorcist] exorcises [parent]!"))
	QDEL_NULL(bound_spirit)
	spirit_name = null

	var/atom/movable/movable_parent = parent
	movable_parent.update_name()

	return TRUE

/datum/component/spirit_holding/proc/on_destroy(datum/source)
	SIGNAL_HANDLER

	to_chat(bound_spirit, span_userdanger("You were destroyed!"))
	QDEL_NULL(bound_spirit)

/datum/component/spirit_holding/proc/on_update_name(datum/source)
	SIGNAL_HANDLER

	var/atom/movable/movable_parent = parent
	if(spirit_name)
		movable_parent.name = spirit_name
	else
		movable_parent.name = initial(movable_parent.name)
