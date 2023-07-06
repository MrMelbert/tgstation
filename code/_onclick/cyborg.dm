
/mob/living/silicon/robot/ClickOn(atom/A, params)
	if(world.time <= next_click)
		return
	next_click = world.time + 1

	if(check_click_intercept(params, A))
		return

	if(stat || lockcharge || IsParalyzed() || IsStun())
		return

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		if(LAZYACCESS(modifiers, CTRL_CLICK))
			CtrlShiftClickOn(A)
			return
		if(LAZYACCESS(modifiers, MIDDLE_CLICK))
			ShiftMiddleClickOn(A)
			return
		ShiftClickOn(A)
		return
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		MiddleClickOn(A, params)
		return
	if(LAZYACCESS(modifiers, ALT_CLICK)) // alt and alt-gr (rightalt)
		AltClickOn(A)
		return
	if(LAZYACCESS(modifiers, CTRL_CLICK))
		CtrlClickOn(A)
		return
	if(LAZYACCESS(modifiers, RIGHT_CLICK) && !module_active)
		var/secondary_result = A.attack_robot_secondary(src, modifiers)
		if(secondary_result == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || secondary_result == SECONDARY_ATTACK_CONTINUE_CHAIN)
			return
		else if (secondary_result != SECONDARY_ATTACK_CALL_NORMAL)
			CRASH("attack_robot_secondary did not return a SECONDARY_ATTACK_* define.")

	if(next_move >= world.time)
		return

	face_atom(A) // change direction to face what you clicked on

	var/obj/item/active_module = get_active_held_item()

	if(isnull(active_module))
		if(get_dist(src, A) <= interaction_range)
			A.attack_robot(src)
		return

	if(incapacitated())
		return

	//while buckled, you can still connect to and control things like doors, but you can't use your modules
	if(buckled)
		to_chat(src, span_warning("You can't use modules while buckled to [buckled]!"))
		return

	//if your "hands" are blocked you shouldn't be able to use modules
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return

	if(active_module == A)
		active_module.attack_self(src, modifiers)
		return

	// This is for module storage management
	if(A == loc || (A in loc) || (A in contents))
		active_module.melee_attack_chain(src, A, params)
		return

	if(!isturf(loc))
		return

	// Actual weapon handling goes here
	if(isturf(A) || isturf(A.loc))
		click_on_with_item(A, active_module, params)
		return

//Give cyborgs hotkey clicks without breaking existing uses of hotkey clicks
// for non-doors/apcs
/mob/living/silicon/robot/CtrlShiftClickOn(atom/target)
	target.BorgCtrlShiftClick(src)

/mob/living/silicon/robot/ShiftClickOn(atom/target)
	target.BorgShiftClick(src)

/mob/living/silicon/robot/CtrlClickOn(atom/target)
	target.BorgCtrlClick(src)

/mob/living/silicon/robot/AltClickOn(atom/target)
	target.BorgAltClick(src)

/atom/proc/BorgCtrlShiftClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	CtrlShiftClick(user)

/obj/machinery/door/airlock/BorgCtrlShiftClick(mob/living/silicon/robot/user) // Sets/Unsets Emergency Access Override Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AICtrlShiftClick(user)
	else
		..()

/atom/proc/BorgShiftClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	ShiftClick(user)

/obj/machinery/door/airlock/BorgShiftClick(mob/living/silicon/robot/user)  // Opens and closes doors! Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AIShiftClick(user)
	else
		..()


/atom/proc/BorgCtrlClick(mob/living/silicon/robot/user) //forward to human click if not overridden
	CtrlClick(user)

/obj/machinery/door/airlock/BorgCtrlClick(mob/living/silicon/robot/user) // Bolts doors. Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AICtrlClick(user)
	else
		..()

/obj/machinery/power/apc/BorgCtrlClick(mob/living/silicon/robot/user) // turns off/on APCs. Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AICtrlClick(user)
	else
		..()

/obj/machinery/power/apc/BorgCtrlShiftClick(mob/living/silicon/robot/user)
	if(get_dist(src, user) <= user.interaction_range)
		AICtrlShiftClick(user)
	else
		..()

/obj/machinery/power/apc/BorgShiftClick(mob/living/silicon/robot/user)
	if(get_dist(src, user) <= user.interaction_range)
		AIShiftClick(user)
	else
		..()

/obj/machinery/power/apc/BorgAltClick(mob/living/silicon/robot/user)
	if(get_dist(src, user) <= user.interaction_range)
		AIAltClick(user)
	else
		..()


/obj/machinery/power/apc/attack_robot_secondary(mob/living/silicon/user, list/modifiers)
	if(get_dist(src, user) <= user.interaction_range)
		return attack_ai_secondary(user, modifiers)
	else
		..()

/obj/machinery/turretid/BorgCtrlClick(mob/living/silicon/robot/user) //turret control on/off. Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AICtrlClick(user)
	else
		..()

/atom/proc/BorgAltClick(mob/living/silicon/robot/user)
	AltClick(user)
	return

/obj/machinery/door/airlock/BorgAltClick(mob/living/silicon/robot/user) // Eletrifies doors. Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AIAltClick(user)
	else
		..()

/obj/machinery/turretid/BorgAltClick(mob/living/silicon/robot/user) //turret lethal on/off. Forwards to AI code.
	if(get_dist(src, user) <= user.interaction_range)
		AIAltClick(user)
	else
		..()

/*
 * As with AI, these are not used in click code,
 * because the code for robots is specific, not generic.
 *
 * If you would like to add advanced features to robot
 * clicks, you can do so here, but you will have to
 * change attack_robot() above to the proper function
 */
/mob/living/silicon/robot/click_on_without_item(atom/A, proximity_flag, list/modifiers)
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	A.attack_robot(src)

/mob/living/silicon/robot/click_on_without_item_at_range(atom/A, modifiers)
	A.attack_robot(src)

/atom/proc/attack_robot(mob/user)
	if (SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_ROBOT, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return

	attack_ai(user)
	return

/**
 * What happens when the cyborg without active module holds right-click on an item. Returns a SECONDARY_ATTACK_* value.
 *
 * Arguments:
 * * user The mob holding the right click
 * * modifiers The list of the custom click modifiers
 */
/atom/proc/attack_robot_secondary(mob/user, list/modifiers)
	if (SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_ROBOT_SECONDARY, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return

	return attack_ai_secondary(user, modifiers)
