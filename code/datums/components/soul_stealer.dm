/**
 * ### Soul Stealer component!
 *
 * Component that attaches to items, making lethal swings with them steal the victims soul, storing it inside the item.
 * Used in the cult bastard sword!
 */
/datum/component/soul_stealer
	/// weakref list of soulstones captured by this item.
	var/list/datum/weakref/weak_souls = list()

/datum/component/soul_stealer/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/soul_stealer/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/component/soul_stealer/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_ITEM_AFTERATTACK))

///signal called on parent being examined
/datum/component/soul_stealer/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("It will steal the soul of anyone it defeats in battle.")

	//clears out any weakrefs that do not exist anymore
	var/list/souls = recursive_list_resolve(weak_souls)

	switch(souls.len)
		if(0)
			examine_list += span_notice("It has not consumed any souls yet.")
		if(1 to 9)
			examine_list += span_notice("There are <b>[length(souls)]</b> souls trapped within it.")
		if(10 to INFINITY)
			examine_list += span_notice("A staggering <b>[length(souls)]</b> souls have been claimed by it! And it hungers for more!")

/datum/component/soul_stealer/proc/on_afterattack(obj/item/source, atom/target, mob/living/user, proximity_flag, click_parameters)
	SIGNAL_HANDLER

	if(!proximity_flag)
		return

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.stat == CONSCIOUS || !human_target.mind)
			return

		INVOKE_ASYNC(src, PROC_REF(try_soulstone_capture), target, user)
		return

	var/list/obj/item/soulstone/souls = recursive_list_resolve(weak_souls)
	list_clear_nulls(souls)
	if(!length(souls))
		return

	INVOKE_ASYNC(src, PROC_REF(try_soulstone_interaction), souls[1], target, user)

/datum/component/soul_stealer/proc/try_soulstone_capture(mob/living/carbon/human/victim, mob/living/captor)
	var/obj/item/soulstone/soulstone = new(parent)
	try_soulstone_interaction(soulstone, victim, captor)
	if(!soulstone.captured_shade)
		qdel(soulstone)
		return

	weak_souls += WEAKREF(soulstone)

/datum/component/soul_stealer/proc/try_soulstone_interaction(obj/item/soulstone/soulstone, atom/hit_atom, mob/living/user)
	return soulstone.pre_attack(hit_atom, user)
