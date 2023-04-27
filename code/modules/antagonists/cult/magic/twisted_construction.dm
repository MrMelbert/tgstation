#define DOAFTER_KEY_TWISTED_CONSTRUCT "doafter_twisted_construction"

/datum/action/cooldown/spell/touch/twisted_construction
	name = "Twisted Construction"
	desc = "Corrupts certain metallic and sanctimonious objects on contact. \
		Includes Soulstones, Airlocks, Iron and Plasteel sheets, and Cyborgs. \
		Examine your hand for more information."
	DEFINE_CULT_ACTION("transmute", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "Ethra p'ni dedol!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	hand_path = /obj/item/melee/touch_attack/cult/construction
	/// How many iron sheets is needed for a construct shell
	var/iron_required_for_shell = 50

/datum/action/cooldown/spell/touch/twisted_construction/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell/blood_cost, charges = 1, health_cost = 12)

/datum/action/cooldown/spell/touch/twisted_construction/is_valid_target(atom/cast_on)
	return !iscarbon(cast_on) // anything but human-ish

/datum/action/cooldown/spell/touch/twisted_construction/register_hand_signals()
	. = ..()
	RegisterSignal(attached_hand, COMSIG_PARENT_EXAMINE, PROC_REF(show_possibilities))

/datum/action/cooldown/spell/touch/twisted_construction/unregister_hand_signals()
	. = ..()
	UnregisterSignal(attached_hand, COMSIG_PARENT_EXAMINE)

/datum/action/cooldown/spell/touch/twisted_construction/proc/show_possibilities(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!IS_CULTIST(user) && !isobserver(user)) // does this really matter?
		return

	var/list/possibilities = list(
		"- Plasteel sheets into Runed metal",
		"- [iron_required_for_shell] iron sheets into a Construct shell",
		"- Living cyborgs into Constructs, after a delay",
		"- Cyborg shells into Construct shells",
		"- Purified soulstones (and any shades inside) into Corrupted soulstones",
		"- Airlocks into brittle Runed airlocks, after a delay",
	)

	examine_list += span_cultbold("<u>A sinister spell used to convert:</u>")
	examine_list += span_cult(jointext(possibilities, "\n"))

/datum/action/cooldown/spell/touch/twisted_construction/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(DOING_INTERACTION(caster, DOAFTER_KEY_TWISTED_CONSTRUCT))
		victim.balloon_alert(caster, "already channeling!")
		return FALSE

	// melbert todo: split all of these off into their own functions, this is nasty-ish

	var/turf/result_turf = get_turf(victim)
	// -- Iron to shells --
	if(istype(victim, /obj/item/stack/sheet/iron))
		var/obj/item/stack/sheet/candidate = victim
		var/old_name = "[candidate]"
		if(candidate.use(iron_required_for_shell))
			var/obj/structure/constructshell/shell = new(result_turf)
			caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [old_name], twisting it into \a [shell]!"))
			shell.balloon_alert(caster, "converted to shell")
			SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
			return TRUE

		candidate.balloon_alert(caster, "need [iron_required_for_shell] sheets!")
		return FALSE

	// -- Plasteel to runed metal --
	else if(istype(victim, /obj/item/stack/sheet/plasteel))
		var/obj/item/stack/sheet/plasteel/candidate = victim
		var/quantity = candidate.amount
		var/old_name = "[candidate]"
		if(!candidate.use(quantity)) // how would this ever fail? no idea
			stack_trace("Somehow, [name] failed to convert [quantity] sheets of plasteel into runed metal.")
			return FALSE

		var/obj/item/stack/sheet/runed_metal/new_metal = new(result_turf, quantity)
		caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [old_name], transforming it into [new_metal.name]!"))
		new_metal.balloon_alert(caster, "converted to runed metal")
		SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
		return TRUE

	// -- Corrupting soulstones --
	else if(istype(victim, /obj/item/soulstone))
		var/obj/item/soulstone/candidate = victim
		if(!candidate.corrupt())
			candidate.balloon_alert(caster, "can't corrupt that!")
			return FALSE

		caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [candidate], corrupting it into a dark red hue!"))
		candidate.balloon_alert(caster, "corrupted")
		SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
		return TRUE

	// -- Cultify airlocks --
	else if(istype(victim, /obj/machinery/door/airlock))
		playsound(result_turf, 'sound/machines/airlockforced.ogg', 50, TRUE)
		do_sparks(5, TRUE, victim)
		victim.balloon_alert(caster, "converting airlock...")
		if(!do_after(caster, 5 SECONDS, victim, interaction_key = DOAFTER_KEY_TWISTED_CONSTRUCT))
			victim.balloon_alert(caster, "interrupted!")
			return FALSE

		caster.visible_message(span_warning("Black ribbons emanate from [caster]'s hand and cling to [victim] - twisting and corrupting it!"))
		victim.narsie_act()
		result_turf.balloon_alert(caster, "conversion complete")
		SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
		return TRUE

	// -- Silicon to Construct --
	else if(istype(target, /mob/living/silicon/robot))
		var/mob/living/silicon/robot/candidate = target
		if(!candidate.mmi && !candidate.shell)
			var/obj/structure/constructshell/shell = new(result_turf)
			caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around [shell], twisting it into \a [shell]!"))
			shell.balloon_alert(caster, "converted to shell")
			SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
			qdel(candidate)
			return TRUE

		caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around [candidate]!"))
		candidate.balloon_alert(caster, "converting to construct...")
		playsound(result_turf, 'sound/machines/airlock_alien_prying.ogg', 80, TRUE)
		var/prev_color = candidate.color
		candidate.color = "black"
		var/datum/callback/checks = CALLBACK(src, PROC_REF(construct_interaction_check), hand, victim, caster)
		if(!do_after(caster, 9 SECONDS, candidate, extra_checks = checks))
			candidate.color = prev_color
			candidate.balloon_alert(caster, "interrupted!")
			return FALSE

		candidate.undeploy()
		candidate.emp_act(EMP_HEAVY)
		var/construct_class = show_radial_menu(caster, src, GLOB.construct_radial_images, custom_check = checks, require_near = TRUE, tooltips = TRUE)
		if(!construct_class)
			return FALSE

		candidate.grab_ghost()
		log_combat(caster, candidate, "converted from silicon to construct via [src]")
		caster.visible_message(span_danger("The dark cloud recedes from what was formerly [candidate], revealing \a [construct_class]!"))
		result_turf.balloon_alert(caster, "conversion complete")
		make_new_construct_from_class(construct_class, THEME_CULT, candidate, caster, FALSE, result_turf)
		candidate.mmi = null
		qdel(candidate)
		return TRUE

	victim.balloon_alert(caster, "invalid target!")
	return FALSE

/datum/action/cooldown/spell/touch/twisted_construction/proc/construct_interaction_check(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(victim) || QDELETED(hand))
		return FALSE
	if(!IsAvailable() || !caster.Adjacent(victim))
		return FALSE
	return TRUE

/obj/item/melee/touch_attack/cult/construction
	name = "twisting aura"
	desc = "Corrupts certain metalic objects on contact."
	color = "#000000" // black

#undef DOAFTER_KEY_TWISTED_CONSTRUCT
