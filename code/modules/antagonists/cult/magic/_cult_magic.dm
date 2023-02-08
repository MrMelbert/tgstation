#define REMOVE_SPELL_KEY "(REMOVE SPELL)"

/datum/cult_magic_holder
	var/datum/antagonist/cult/linked_cultist
	var/datum/action/spell_creator

	var/unempowered_spell_limit = RUNELESS_MAX_BLOODCHARGE
	var/empowered_spell_limit = MAX_BLOODCHARGE
	var/list/datum/action/cooldown/spell/spells = list()

	var/list/possible_spell_types

/datum/cult_magic_holder/New()
	spell_creator = new(src)
	setup_spell_types()

/datum/cult_magic_holder/proc/setup_spell_types()
	var/static/list/blood_cult_spells
	if(!blood_cult_spells)
		blood_cult_spells = list(

		)

	possible_spell_types = blood_cult_spells

/datum/cult_magic_holder/proc/link_to_cultist(datum/antagonist/cult/linked_cultist)
	src.linked_cultist = linked_cultist

	var/mob/living/cultist = linked_cultist.owner.current
	spell_creator.Grant(cultist)
	for(var/datum/action/cooldown/spell/spell as anything in spells)
		spell.Grant(cultist)

	position_spells()

/datum/cult_magic_holder/proc/position_spells()
	for(var/datum/hud/hud as anything in spell_creator.viewers)
		var/our_view = hud.mymob?.client?.view || "15x15"
		var/atom/movable/screen/movable/action_button/button = spell_creator.viewers[hud]
		var/position = screen_loc_to_offset(button.screen_loc)
		var/spells_iterated = 0
		for(var/datum/action/innate/cult/blood_spell/blood_spell in spells)
			spells_iterated += 1
			// if(blood_spell.positioned)
			// 	continue
			var/atom/movable/screen/movable/action_button/moving_button = blood_spell.viewers[hud]
			if(!moving_button)
				continue
			var/our_x = position[1] + spells_iterated * world.icon_size // Offset any new buttons into our list
			hud.position_action(moving_button, offset_to_screen_loc(our_x, position[2], our_view))
			// blood_spell.positioned = TRUE

/datum/cult_magic_holder/proc/add_new_spell(datum/action/cooldown/spell/spell_type, mob/living/give_to)
	var/datum/action/cooldown/spell/new_spell = new spell_type(src)
	new_spell.Grant(give_to)
	spells += new_spell
	position_spells()
	RegisterSignal(new_spell, COMSIG_PARENT_QDELETING, PROC_REF(clear_spell_ref))

/datum/cult_magic_holder/proc/clear_spell_ref(datum/source)
	SIGNAL_HANDLER
	spells -= source

/datum/cult_magic_holder/Destroy()
	QDEL_LIST(spells)
	QDEL_NULL(spell_creator)
	linked_cultist = null
	return ..()

/datum/action/cult_spell_creator
	name = "Prepare Blood Magic"
	button_icon_state = "carve"
	desc = "Prepare blood magic by carving runes into your flesh. This is easier with an <b>empowering rune</b>."
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

	if(length(spells) >= limit)
		return

	before_spell_made(selected_spell)

	if(!do_after(owner, (10 SECONDS) - rune * (6 SECONDS), owner))
		return

	var/datum/action/cooldown/spell/new_spell = parent.add_new_spell(selected_spell)
	after_spell_made(new_spell)
	return TRUE
