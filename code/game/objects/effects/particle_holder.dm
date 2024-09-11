/obj/effect/abstract/particle_holder
	name = "particle holder"
	desc = "How are you reading this? Please make a bug report :)"
	appearance_flags = parent_type::appearance_flags | KEEP_APART | KEEP_TOGETHER
	vis_flags = VIS_INHERIT_PLANE
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	/// Holds info about how this particle emitter works
	/// See \code\__DEFINES\particles.dm
	var/particle_flags = NONE

/obj/effect/abstract/particle_holder/Destroy(force)
	QDEL_NULL(particles)
	return ..()

/// Sets the particles position to the passed coordinates
/obj/effect/abstract/particle_holder/proc/set_particle_position(x = 0, y = 0, z = 0)
	particles.position = list(x, y, z)

/obj/effect/abstract/particle_holder/Initialize(mapload, particle_path = /particles/smoke, particle_flags = NONE)
	. = ..()
	// Mouse opacity can get set to opaque by some objects when placed into the object's contents (storage containers).
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	src.particle_flags = particle_flags
	particles = new particle_path()

/**
 * Objects can only have one particle on them at a time
 * so we use these abstract effects to hold and display the effects.
 *
 * You know, so multiple particle effects can exist at once.
 * Also because some objects do not display particles due to how their visuals are built
 */
/obj/effect/abstract/particle_holder/per_atom
	//// The only atom we're linked to, we go away when it does
	VAR_PRIVATE/atom/parent

/obj/effect/abstract/particle_holder/per_atom/Initialize(mapload, particle_path = /particles/smoke, particle_flags = NONE)
	. = ..()
	if(!loc)
		stack_trace("particle holder was created with no loc!")
		return INITIALIZE_HINT_QDEL
	// We nullspace ourselves because some objects use their contents (e.g. storage) and some items may drop everything in their contents on deconstruct.
	parent = loc
	loc = null

	// /atom doesn't have vis_contents, /turf and /atom/movable do
	var/atom/movable/lie_about_areas = parent
	lie_about_areas.vis_contents += src
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(parent_deleted))

	if(particle_flags & PARTICLE_ATTACH_MOB)
		RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	on_move(parent, null, NORTH)

/obj/effect/abstract/particle_holder/per_atom/Destroy(force)
	parent = null
	return ..()

/// Non movables don't delete contents on destroy, so we gotta do this
/obj/effect/abstract/particle_holder/per_atom/proc/parent_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// signal called when a parent that's been hooked into this moves
/// does a variety of checks to ensure overrides work out properly
/obj/effect/abstract/particle_holder/per_atom/proc/on_move(atom/movable/attached, atom/oldloc, direction)
	SIGNAL_HANDLER

	if(!(particle_flags & PARTICLE_ATTACH_MOB))
		return

	//remove old
	if(ismob(oldloc))
		var/mob/particle_mob = oldloc
		particle_mob.vis_contents -= src

	// If we're sitting in a mob, we want to emit from it too, for vibes and shit
	if(ismob(attached.loc))
		var/mob/particle_mob = attached.loc
		particle_mob.vis_contents += src

/**
 * A subtype of particle holder intended to be used in situations
 * where you might have a particle effect on dozens of atoms in a small area
 *
 * Particle spam can cause client lag so we we can relieve that by just having
 * a few effects (pooling them) and using vis contents to put them on multiple at once
 */
/obj/effect/abstract/particle_holder/pooled
	var/list/displayed_to = list()

/obj/effect/abstract/particle_holder/pooled/Destroy(force)
	if(!force)
		stack_trace("Pooled particle holder being qdeleted!")
	for(var/i in displayed_to)
		remove_atom(i)
	return ..()

/// Shows this particle on the passed atom
/// Works on movables or turfs
/obj/effect/abstract/particle_holder/pooled/proc/add_atom(atom/movable/adding)
	if(adding in displayed_to)
		return

	adding.vis_contents += src
	RegisterSignal(adding, COMSIG_QDELETING, PROC_REF(displayed_deleted))

	if(particle_flags & PARTICLE_ATTACH_MOB)
		RegisterSignal(adding, COMSIG_MOVABLE_MOVED, PROC_REF(displayed_moved))

/// Removes this particle from the passed atom
/obj/effect/abstract/particle_holder/pooled/proc/remove_atom(atom/movable/removing)
	if(!(removing in displayed_to))
		return

	removing.vis_contents -= src
	UnregisterSignal(removing, COMSIG_QDELETING)
	UnregisterSignal(removing, COMSIG_MOVABLE_MOVED)

/obj/effect/abstract/particle_holder/pooled/proc/displayed_deleted(atom/movable/source)
	SIGNAL_HANDLER
	remove_atom(source)

/obj/effect/abstract/particle_holder/pooled/proc/displayed_moved(atom/movable/source, atom/old_loc, ...)
	SIGNAL_HANDLER
	if(!(particle_flags & PARTICLE_ATTACH_MOB))
		return
	if(source.loc == old_loc)
		return
	remove_atom(source)
	add_atom(source)

/proc/add_pooled_particle_effect(atom/movable/particle_atom, particle_typepath, particle_flags = NONE, key = "default", pool_size = 5)
	ASSERT(ispath(particle_typepath, /particles))
	ASSERT(ismovable(particle_atom) || isturf(particle_atom))

	var/static/list/pooled_particles = list()
	var/pool_key = "[particle_typepath]_[key]_[particle_flags]"
	var/list/pool = pooled_particles[pool_key]
	if(isnull(pool))
		pool = list()
		for(var/i in 1 to pool_size)
			pool[new /obj/effect/abstract/particle_holder/pooled(null, particle_typepath, particle_flags)] = 0

		pooled_particles[particle_typepath] = pool

	var/obj/effect/abstract/particle_holder/pooled/least_used = pool[1]
	for(var/next_used in pool)
		if(pool[next_used] < pool[least_used])
			least_used = next_used

	least_used.add_atom(particle_atom)
	return least_used

/proc/remove_pooled_particle_effect(atom/movable/particle_atom, particle_typepath)
	for(var/obj/effect/abstract/particle_holder/pooled/pool in particle_atom.vis_contents)
		if(pool.particles.type == particle_typepath)
			pool.remove_atom(particle_atom)
