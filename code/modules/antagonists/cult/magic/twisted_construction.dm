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

/// Converts [iron_required_for_shell] iron into a construct shell.
/datum/action/cooldown/spell/touch/twisted_construction/proc/convert_iron(obj/item/stack/sheet/iron/candidate, mob/living/carbon/caster)
	var/turf/result_turf = get_turf(candidate)
	var/old_name = "[candidate]"
	if(candidate.use(iron_required_for_shell))
		var/obj/structure/constructshell/shell = new(result_turf)
		caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [old_name], twisting it into \a [shell]!"))
		shell.balloon_alert(caster, "converted to shell")
		return TRUE

	candidate.balloon_alert(caster, "need [iron_required_for_shell] sheets!")
	return FALSE

/// Converts a stack of plasteel to an equal sized stack of runed metal.
/datum/action/cooldown/spell/touch/twisted_construction/proc/convert_plasteel(obj/item/stack/sheet/plasteel/candidate, mob/living/carbon/caster)
	var/turf/result_turf = get_turf(candidate)
	var/quantity = candidate.amount
	var/old_name = "[candidate]"
	if(!candidate.use(quantity)) // how would this ever fail? no idea
		stack_trace("Somehow, [name] failed to convert [quantity] sheets of plasteel into runed metal.")
		return FALSE

	var/obj/item/stack/sheet/runed_metal/new_metal = new(result_turf, quantity)
	caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [old_name], transforming it into [new_metal.name]!"))
	new_metal.balloon_alert(caster, "converted to runed metal")
	return TRUE

/// Corrupts a pure soulstone to be cult-y and not holy-y.
/datum/action/cooldown/spell/touch/twisted_construction/proc/blight_soulstone(obj/item/soulstone/candidate, mob/living/carbon/caster)
	if(!candidate.corrupt())
		candidate.balloon_alert(caster, "can't corrupt that!")
		return FALSE

	caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around \the [candidate], corrupting it into a dark red hue!"))
	candidate.balloon_alert(caster, "corrupted")
	return TRUE

/// Converts an airlock from normal to runed, which stuns non-cultists.
/datum/action/cooldown/spell/touch/twisted_construction/proc/curse_airlock(obj/machinery/door/airlock/candidate, mob/living/carbon/caster)
	var/turf/result_turf = get_turf(candidate)
	playsound(result_turf, 'sound/machines/airlockforced.ogg', 50, TRUE)
	do_sparks(5, TRUE, candidate)
	candidate.balloon_alert(caster, "converting airlock...")
	if(!do_after(caster, 5 SECONDS, candidate, interaction_key = DOAFTER_KEY_TWISTED_CONSTRUCT))
		candidate.balloon_alert(caster, "interrupted!")
		return FALSE

	caster.visible_message(span_warning("Black ribbons emanate from [caster]'s hand and cling to [candidate] - twisting and corrupting it!"))
	candidate.narsie_act()
	result_turf.balloon_alert(caster, "conversion complete")
	return TRUE

/// When used on a cyborg shell, converts it to a construct shell.
/// Otherwise when used on an active cyborg, converts it to a construct.
/datum/action/cooldown/spell/touch/twisted_construction/proc/convert_silicon(mob/living/silicon/robot/candidate, mob/living/carbon/caster, obj/item/melee/touch_attack/hand)
	var/turf/result_turf = get_turf(candidate)
	if(!candidate.mmi && !candidate.shell)
		var/obj/structure/constructshell/shell = new(result_turf)
		caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around [shell], twisting it into \a [shell]!"))
		shell.balloon_alert(caster, "converted to shell")
		qdel(candidate)
		return TRUE

	caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around [candidate]!"))
	candidate.balloon_alert(caster, "converting to construct...")
	playsound(result_turf, 'sound/machines/airlock_alien_prying.ogg', 80, TRUE)
	var/prev_color = candidate.color
	candidate.color = "black"
	var/datum/callback/checks = CALLBACK(src, PROC_REF(construct_interaction_check), hand, candidate, caster)
	if(!do_after(caster, 9 SECONDS, candidate, extra_checks = checks))
		candidate.color = prev_color
		candidate.balloon_alert(caster, "interrupted!")
		return FALSE

	candidate.undeploy()
	candidate.emp_act(EMP_HEAVY)
	var/construct_class = show_radial_menu(caster, src, GLOB.construct_radial_images, custom_check = checks, require_near = TRUE, tooltips = TRUE)
	if(!construct_class)
		candidate.color = prev_color
		return FALSE

	candidate.grab_ghost()
	log_combat(caster, candidate, "converted from silicon to construct via [src]")
	caster.visible_message(span_danger("The dark cloud recedes from what was formerly [candidate], revealing \a [construct_class]!"))
	result_turf.balloon_alert(caster, "conversion complete")
	make_new_construct_from_class(construct_class, THEME_CULT, candidate, caster, FALSE, result_turf)
	candidate.mmi = null
	qdel(candidate)
	return TRUE

/datum/action/cooldown/spell/touch/twisted_construction/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(DOING_INTERACTION(caster, DOAFTER_KEY_TWISTED_CONSTRUCT))
		victim.balloon_alert(caster, "already channeling!")
		return FALSE

	// -- Iron to shells --
	if(istype(victim, /obj/item/stack/sheet/iron))
		. = convert_iron(victim, caster)

	// -- Plasteel to runed metal --
	else if(istype(victim, /obj/item/stack/sheet/plasteel))
		. = convert_plasteel(victim, caster)

	// -- Corrupting soulstones --
	else if(istype(victim, /obj/item/soulstone))
		. = blight_soulstone(victim, caster)

	// -- Cultify airlocks --
	else if(istype(victim, /obj/machinery/door/airlock))
		. = curse_airlock(victim, caster)

	// -- Silicon to Construct --
	else if(istype(target, /mob/living/silicon/robot))
		. = convert_silicon(victim, caster, hand)

	if(.)
		SEND_SOUND(caster, sound('sound/effects/magic.ogg', 0, 1, 25))
	else
		victim.balloon_alert(caster, "invalid target!")

	return .

/datum/action/cooldown/spell/touch/twisted_construction/proc/construct_interaction_check(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(victim) || QDELETED(hand))
		return FALSE
	if(!IsAvailable() || !caster.Adjacent(victim))
		return FALSE
	return TRUE

/obj/item/melee/touch_attack/cult/construction
	name = "twisting aura"
	desc = "Corrupts certain metalic objects on contact."
	color = "#000000"

#undef DOAFTER_KEY_TWISTED_CONSTRUCT
