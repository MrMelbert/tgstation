#define REMOVE_SPELL_KEY "(REMOVE SPELL)"

/**
 * ## Cult magic holder datum
 *
 * This datum holds a cultist's blood magic.
 * Every cultist has one of these, and they can use it to gain spells to use on their mission.
 *
 * When this datum is deleted, all associated spells will vanish as well.
 */
/datum/cult_magic_holder
	/// This is the core action that lets the cultist create spells.
	var/datum/action/cult_spell_creator/spell_creator
	/// A list to all the spell datums we've created for this cultist.
	/// All fully deleted when this datum holder is deleted.
	var/list/datum/action/cooldown/spell/spells = list()
	/// When unempowered or unaided, the cultist can only invoke this many spells at once.
	var/unempowered_spell_limit = 1
	/// When empowered, the cultist can invoke up to this many spells at once.
	var/empowered_spell_limit = 4
	/// A static-ish list of all spell types the spell creator can make for this cultist.
	/// Generated via [/datum/cult_magic_holder/proc/setup_spell_types].
	var/list/possible_spell_types

/datum/cult_magic_holder/New(mob/living/linked_cultist)
	spell_creator = new(src)
	possible_spell_types = setup_spell_types()
	if(linked_cultist)
		give_to_cultist(linked_cultist)

/// Set up the [possible_spell_types] list.
/// Contains all spell types the cultist can invoke.
/datum/cult_magic_holder/proc/setup_spell_types()
	return GLOB.cult_spell_types

/// Gives the passed cultist the creator action and all spells learned.
/datum/cult_magic_holder/proc/give_to_cultist(mob/living/cultist)
	spell_creator.Grant(cultist)
	for(var/datum/action/cooldown/spell/spell as anything in spells)
		spell.Grant(cultist)

	position_spells()

/// Handles re-aligning and slotting in all the spells into a neat bar in the middle-bottom of the screen, rather than by the top left.
/datum/cult_magic_holder/proc/position_spells()
	for(var/datum/hud/hud as anything in spell_creator.viewers)
		var/our_view = hud.mymob?.client?.view || "15x15"
		var/atom/movable/screen/movable/action_button/button = spell_creator.viewers[hud]
		var/position = screen_loc_to_offset(button.screen_loc)
		var/spells_iterated = 0
		for(var/datum/action/cooldown/spell/blood_spell as anything in spells)
			spells_iterated += 1
			// if(blood_spell.positioned)
			// 	continue
			var/atom/movable/screen/movable/action_button/moving_button = blood_spell.viewers[hud]
			if(!moving_button)
				continue
			var/our_x = position[1] + spells_iterated * world.icon_size // Offset any new buttons into our list
			hud.position_action(moving_button, offset_to_screen_loc(our_x, position[2], our_view))
			// blood_spell.positioned = TRUE

/**
 * Wrapper for adding a new spell to the spells list.
 *
 * * spell_type - typepath spell being added
 * * give_to - who is learning it
 */
/datum/cult_magic_holder/proc/add_new_spell(datum/action/cooldown/spell/spell_type, mob/living/give_to)
	var/datum/action/cooldown/spell/new_spell = new spell_type(src)
	new_spell.Grant(give_to)
	spells += new_spell
	position_spells()
	RegisterSignal(new_spell, COMSIG_PARENT_QDELETING, PROC_REF(clear_spell_ref))

/// Signal proc to clean up references when spell datums are deleted
/datum/cult_magic_holder/proc/clear_spell_ref(datum/source)
	SIGNAL_HANDLER
	spells -= source

/datum/cult_magic_holder/Destroy()
	QDEL_LIST(spells)
	QDEL_NULL(spell_creator)
	return ..()

/// Simple action that allows a player to prepare a cult spell for their cult magic holder
/datum/action/cult_spell_creator // melbert todo: needs cult subtype shit
	name = "Prepare Blood Magic"
	desc = "Prepare blood magic by carving runes into your flesh. This is easier with an <b>empowering rune</b>."
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "carve"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	buttontooltipstyle = "cult"
	default_button_position = DEFAULT_BLOODSPELLS

	/// The antag datum required to use this action
	var/required_antag_datum = /datum/antagonist/cult

	/// Whether this action is currently in use or not
	VAR_FINAL/currently_carving = FALSE

/datum/action/cult_spell_creator/IsAvailable(feedback)
	. = ..()
	if(!.)
		return FALSE
	if(!owner.mind.has_antag_datum(required_antag_datum))
		return FALSE
	if(currently_carving)
		if(feedback)
			owner.balloon_alert(owner, "already preparing a spell!")
		return FALSE
	return TRUE

/datum/action/cult_spell_creator/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	currently_carving = TRUE
	. = create_spell_process()
	currently_carving = FALSE

/datum/action/cult_spell_creator/proc/is_empowered()
	return locate(/obj/effect/rune/empower) in range(1, owner)

/datum/action/cult_spell_creator/proc/remove_spell()
	var/datum/cult_magic_holder/parent = target
	var/nullify_spell = tgui_input_list(owner, "Spell to remove", "Current Spells", parent.spells)
	if(isnull(nullify_spell))
		return FALSE
	qdel(nullify_spell)
	parent.spells -= nullify_spell
	return TRUE

/datum/action/cult_spell_creator/proc/before_spell_made(datum/action/cooldown/spell/spell_type)
	to_chat(owner, span_warning("You begin to carve unnatural symbols into your flesh!"))
	SEND_SOUND(owner, sound('sound/weapons/slice.ogg', 0, 1, 10))

/datum/action/cult_spell_creator/proc/after_spell_made(datum/action/cooldown/spell/new_spell)
	to_chat(owner, span_warning("Your wounds glow with power, you have prepared a [new_spell.name] invocation!"))
	if(!ishuman(owner))
		return

	var/empowered = !!is_empowered() // Cast to boolean so we can multiply it
	var/mob/living/carbon/human/human_owner = owner
	human_owner.bleed(40 - empowered * 32)

/datum/action/cult_spell_creator/proc/create_spell_process()
	var/datum/cult_magic_holder/parent = target
	if(!istype(target))
		to_chat(target, span_warning("Your magic does not come to you, for whatever reason. Contact your local diety!"))
		CRASH("Cult spell creator was created with an invalid target! It's supposed to be a blood magic holder.")

	var/lower_limit = parent.unempowered_spell_limit
	var/upper_limit = parent.empowered_spell_limit

	var/rune = !!is_empowered()
	var/limit = rune ? lower_limit : upper_limit

	if(length(parent.spells) >= limit)
		if(rune)
			to_chat(owner, span_warning("You cannot prepare more than [upper_limit] spells. <b>Pick a spell to remove.</b>"))
		else
			to_chat(owner, span_warning("<u>You cannot prepare more than [lower_limit] spells without being empowered! <b>Pick a spell to remove.</b></u>"))

		if(!remove_spell())
			return

	var/list/possible_spells_assoc = list()
	for(var/datum/action/cooldown/spell/spell_type as anything in parent.possible_spell_types)
		var/cult_name = initial(spell_type.name)
		possible_spells_assoc[cult_name] = spell_type
	possible_spells_assoc[REMOVE_SPELL_KEY] = 1

	var/entered_spell_name = tgui_input_list(owner, "Blood spell to prepare", "Spell Choices", possible_spells_assoc)
	if(isnull(entered_spell_name))
		return
	if(entered_spell_name == REMOVE_SPELL_KEY)
		return remove_spell()

	var/datum/action/cooldown/spell/selected_spell = possible_spells_assoc[entered_spell_name]
	if(QDELETED(src) || !IsAvailable() || currently_carving)
		return
	if(!ispath(selected_spell))
		return

	// Re-do these, to check if they changed
	rune = !!is_empowered()
	limit = rune ? lower_limit : upper_limit

	if(length(parent.spells) >= limit)
		return

	before_spell_made(selected_spell)

	if(!do_after(owner, (10 SECONDS) - rune * (6 SECONDS), owner))
		return

	var/datum/action/cooldown/spell/new_spell = parent.add_new_spell(selected_spell)
	after_spell_made(new_spell)
	return TRUE

/// Used for cult touch spells
/obj/item/melee/touch_attack/cult

/obj/item/melee/touch_attack/cult/interact(mob/user)
	// using in hand (attack self-ing) is a quick way to cast it on yourself.
	// any other interactions (like attack hand-ing) will also work if the flags are set.
	melee_attack_chain(user, user)

#undef REMOVE_SPELL_KEY
