/datum/mutation/human/mind_block
	name = "Mind Block"
	desc = "Your mind is immune to telepathic probing."
	quality = POSITIVE
	text_gain_indication = span_notice("You feel a mental block settle into place.")
	instability = 15
	difficulty = 12
	synchronizer_coeff = 1
	VAR_PRIVATE/datum/component/anti_magic/comp

/datum/mutation/human/mind_block/modify()
	QDEL_NULL(comp)
	comp = owner.AddComponent(
		/datum/component/anti_magic,
		antimagic_flags = MAGIC_RESISTANCE_MIND,
		self_block_flags = ((GET_MUTATION_SYNCHRONIZER(src) == 1) ? MAGIC_RESISTANCE_MIND : NONE),
	)

/datum/mutation/human/mind_block/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return

	QDEL_NULL(comp)
