
/obj/effect/decal/cleanable/food
	icon = 'icons/effects/tomatodecal.dmi'
	gender = NEUTER
	beauty = -100

/obj/effect/decal/cleanable/food/tomato_smudge
	name = "tomato smudge"
	desc = "It's red."
	icon_state = "tomato_floor1"
	random_icon_states = list("tomato_floor1", "tomato_floor2", "tomato_floor3")

/obj/effect/decal/cleanable/food/plant_smudge
	name = "plant smudge"
	desc = "Chlorophyll? More like borophyll!"
	icon_state = "smashed_plant"

/obj/effect/decal/cleanable/food/egg_smudge
	name = "smashed egg"
	desc = "Seems like this one won't hatch."
	icon_state = "smashed_egg1"
	random_icon_states = list("smashed_egg1", "smashed_egg2", "smashed_egg3")

/obj/effect/decal/cleanable/food/pie_smudge //honk
	name = "smashed pie"
	desc = "It's pie cream from a cream pie."
	icon_state = "smashed_pie"

/obj/effect/decal/cleanable/food/salt
	name = "salt pile"
	desc = "A sizable pile of table salt. Someone must be upset."
	icon_state = "salt_pile"
	var/safepasses = 3 //how many times can this salt pile be passed before dissipating

/obj/effect/decal/cleanable/food/salt/Initialize(mapload, list/datum/disease/diseases)
	. = ..()
	var/static/list/salt_loc_connections = list(
		COMSIG_INCORPOREAL_MOVE_CHECK = .proc/on_incorporeal_move,
	)
	AddElement(/datum/element/connect_loc, salt_loc_connections)


/obj/effect/decal/cleanable/food/salt/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_species(mover, /datum/species/snail))
		return FALSE

/obj/effect/decal/cleanable/food/salt/Bumped(atom/movable/AM)
	. = ..()
	if(is_species(AM, /datum/species/snail))
		to_chat(AM, span_danger("Your path is obstructed by [span_phobia("salt")]."))

/obj/effect/decal/cleanable/food/salt/on_entered(datum/source, atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return
	if(iscarbon(AM))
		var/mob/living/carbon/C = AM
		if(C.m_intent == MOVE_INTENT_WALK)
			return
	safepasses--
	if(safepasses <= 0 && !QDELETED(src))
		qdel(src)

/obj/effect/decal/cleanable/food/salt/proc/on_incorporeal_move(datum/source, mob/mover, incorporeal_move_flags)
	SIGNAL_HANDLER

	if(!(incorporeal_move_flags & INCORPOREAL_MOVE_BLOCKBY_SALT))
		return

	to_chat(mover, span_warning("[src] bars your passage!"))
	if(isrevenant(mover))
		var/mob/living/simple_animal/revenant/ghost = mover
		ghost.reveal(20)
		ghost.stun(20)

	return BLOCK_INCORPOREAL_MOVE

/obj/effect/decal/cleanable/food/flour
	name = "flour"
	desc = "It's still good. Four second rule!"
	icon_state = "flour"
