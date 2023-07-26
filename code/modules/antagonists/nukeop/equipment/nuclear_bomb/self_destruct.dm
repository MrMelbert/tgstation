/obj/machinery/nuclearbomb/selfdestruct
	name = "station self-destruct terminal"
	desc = "For when it all gets too much to bear. Do not taunt."
	icon = 'icons/obj/machines/nuke_terminal.dmi'
	icon_state = "nuclearbomb_base"
	anchored = TRUE //stops it being moved

/obj/machinery/nuclearbomb/selfdestruct/set_anchor()
	return

/obj/machinery/nuclearbomb/selfdestruct/toggle_nuke_safety()
	. = ..()
	if(timing)
		SSmapping.add_nuke_threat(src)
	else
		SSmapping.remove_nuke_threat(src)

/obj/machinery/nuclearbomb/selfdestruct/toggle_nuke_armed()
	. = ..()
	if(timing)
		SSmapping.add_nuke_threat(src)
	else
		SSmapping.remove_nuke_threat(src)

/obj/machinery/nuclearbomb/selfdestruct/arm_nuke(mob/armer)
	. = ..()
	if(!armer.special_role && !length(armer.mind?.antag_datums))
		armer.client?.give_award(/datum/award/achievement/misc/set_up_the_self_destruct, armer)
