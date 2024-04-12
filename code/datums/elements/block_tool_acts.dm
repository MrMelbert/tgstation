/datum/element/block_tool_acts
	/// Default list of tools that gets blocked by this element.
	var/list/default_tool_acts = list(
		TOOL_CROWBAR,
		TOOL_MULTITOOL,
		TOOL_SCREWDRIVER,
		TOOL_WELDER,
		TOOL_WIRECUTTER,
		TOOL_WRENCH,
	)

/datum/element/block_tool_acts/Attach(datum/target, list/to_block = default_tool_acts)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE

	if(!islist(to_block))
		to_block = list(to_block)

	for(var/tool in to_block)
		RegisterSignals(target, list(COMSIG_ATOM_TOOL_ACT(tool), COMSIG_ATOM_SECONDARY_TOOL_ACT(tool)), PROC_REF(do_block))

/datum/element/block_tool_acts/Detach(datum/source, ...)
	. = ..()
	for(var/tool in GLOB.all_tool_types)
		UnregisterSignals(source, list(COMSIG_ATOM_TOOL_ACT(tool), COMSIG_ATOM_SECONDARY_TOOL_ACT(tool)))

/datum/element/block_tool_acts/proc/do_block(datum/source, ...)
	SIGNAL_HANDLER
	return ITEM_INTERACT_SKIP_TO_ATTACK
