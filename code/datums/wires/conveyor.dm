#define WIRE_CONVEYOR_FORWARDS "Conveyor Forwards"
#define WIRE_CONVEYOR_BACKWARDS "Conveyor Backwards"

/datum/wires/conveyor
	holder_type = /obj/machinery/conveyor_switch
	proper_name = "Conveyor"

/datum/wires/conveyor/New(atom/holder)
	wires = list(
		WIRE_CONVEYOR_FORWARDS,
		WIRE_CONVEYOR_BACKWARDS,
	)
	add_duds(1)
	return ..()

/datum/wires/conveyor/on_pulse(wire)
	var/obj/machinery/conveyor_switch/the_switch = holder
	switch(wire)
		if(WIRE_CONVEYOR_FORWARDS)
			the_switch.send_forwards()
		if(WIRE_CONVEYOR_BACKWARDS)
			the_switch.send_backwards()

/datum/wires/conveyor/on_cut(wire, mend)
	var/obj/machinery/conveyor_switch/the_switch = holder
	// If either movement wire is cut, lock position
	if(WIRE_CONVEYOR_FORWARDS in cut_wires)
		the_switch.lock_position = TRUE
	else if(WIRE_CONVEYOR_BACKWARDS in cut_wires)
		the_switch.lock_position = TRUE
	// Only unlock if both movement wires are uncut + this is a mend action
	else if(mend)
		the_switch.lock_position = FALSE

#undef WIRE_CONVEYOR_FORWARDS
#undef WIRE_CONVEYOR_BACKWARDS
