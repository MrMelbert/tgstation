// Admin Tab - Event Verbs

/client/proc/cmd_admin_subtle_message(mob/M in GLOB.mob_list)
	set category = "Admin.Events"
	set name = "Subtle Message"

	if(!ismob(M))
		return
	if(!check_rights(R_ADMIN))
		return

	message_admins("[key_name_admin(src)] has started answering [ADMIN_LOOKUPFLW(M)]'s prayer.")
	var/msg = input("Message:", text("Subtle PM to [M.key]")) as text|null

	if(!msg)
		message_admins("[key_name_admin(src)] decided not to answer [ADMIN_LOOKUPFLW(M)]'s prayer")
		return
	if(usr)
		if (usr.client)
			if(usr.client.holder)
				to_chat(M, "<i>You hear a voice in your head... <b>[msg]</i></b>", confidential = TRUE)

	log_admin("SubtlePM: [key_name(usr)] -> [key_name(M)] : [msg]")
	msg = span_adminnotice("<b> SubtleMessage: [key_name_admin(usr)] -> [key_name_admin(M)] :</b> [msg]")
	message_admins(msg)
	admin_ticket_log(M, msg)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Subtle Message") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_headset_message(mob/M in GLOB.mob_list)
	set category = "Admin.Events"
	set name = "Headset Message"

	admin_headset_message(M)

/client/proc/admin_headset_message(mob/M in GLOB.mob_list, sender = null)
	var/mob/living/carbon/human/H = M

	if(!check_rights(R_ADMIN))
		return

	if(!istype(H))
		to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human", confidential = TRUE)
		return
	if(!istype(H.ears, /obj/item/radio/headset))
		to_chat(usr, "The person you are trying to contact is not wearing a headset.", confidential = TRUE)
		return

	if (!sender)
		sender = input("Who is the message from?", "Sender") as null|anything in list(RADIO_CHANNEL_CENTCOM,RADIO_CHANNEL_SYNDICATE)
		if(!sender)
			return

	message_admins("[key_name_admin(src)] has started answering [key_name_admin(H)]'s [sender] request.")
	var/input = input("Please enter a message to reply to [key_name(H)] via their headset.","Outgoing message from [sender]", "") as text|null
	if(!input)
		message_admins("[key_name_admin(src)] decided not to answer [key_name_admin(H)]'s [sender] request.")
		return

	log_directed_talk(mob, H, input, LOG_ADMIN, "reply")
	message_admins("[key_name_admin(src)] replied to [key_name_admin(H)]'s [sender] message with: \"[input]\"")
	to_chat(H, span_hear("You hear something crackle in your ears for a moment before a voice speaks. \"Please stand by for a message from [sender == "Syndicate" ? "your benefactor" : "Central Command"]. Message as follows[sender == "Syndicate" ? ", agent." : ":"] <b>[input].</b> Message ends.\""), confidential = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Headset Message") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_world_narrate()
	set category = "Admin.Events"
	set name = "Global Narrate"

	if(!check_rights(R_ADMIN))
		return

	var/msg = input("Message:", text("Enter the text you wish to appear to everyone:")) as text|null

	if (!msg)
		return
	to_chat(world, "[msg]", confidential = TRUE)
	log_admin("GlobalNarrate: [key_name(usr)] : [msg]")
	message_admins(span_adminnotice("[key_name_admin(usr)] Sent a global narrate"))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Global Narrate") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_local_narrate(atom/A)
	set category = "Admin.Events"
	set name = "Local Narrate"

	if(!check_rights(R_ADMIN))
		return
	if(!A)
		return
	var/range = input("Range:", "Narrate to mobs within how many tiles:", 7) as num|null
	if(!range)
		return
	var/msg = input("Message:", text("Enter the text you wish to appear to everyone within view:")) as text|null
	if (!msg)
		return
	for(var/mob/M in view(range,A))
		to_chat(M, msg, confidential = TRUE)

	log_admin("LocalNarrate: [key_name(usr)] at [AREACOORD(A)]: [msg]")
	message_admins(span_adminnotice("<b> LocalNarrate: [key_name_admin(usr)] at [ADMIN_VERBOSEJMP(A)]:</b> [msg]<BR>"))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Local Narrate") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_direct_narrate(mob/M)
	set category = "Admin.Events"
	set name = "Direct Narrate"

	if(!check_rights(R_ADMIN))
		return

	if(!M)
		M = input("Direct narrate to whom?", "Active Players") as null|anything in GLOB.player_list

	if(!M)
		return

	var/msg = input("Message:", text("Enter the text you wish to appear to your target:")) as text|null

	if( !msg )
		return

	to_chat(M, msg, confidential = TRUE)
	log_admin("DirectNarrate: [key_name(usr)] to ([M.name]/[M.key]): [msg]")
	msg = span_adminnotice("<b> DirectNarrate: [key_name(usr)] to ([M.name]/[M.key]):</b> [msg]<BR>")
	message_admins(msg)
	admin_ticket_log(M, msg)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Direct Narrate") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_add_freeform_ai_law()
	set category = "Admin.Events"
	set name = "Add Custom AI law"

	if(!check_rights(R_ADMIN))
		return

	var/input = input(usr, "Please enter anything you want the AI to do. Anything. Serious.", "What?", "") as text|null
	if(!input)
		return

	log_admin("Admin [key_name(usr)] has added a new AI law - [input]")
	message_admins("Admin [key_name_admin(usr)] has added a new AI law - [input]")

	var/show_log = tgui_alert(usr, "Show ion message?", "Message", list("Yes", "No"))
	var/announce_ion_laws = (show_log == "Yes" ? 100 : 0)

	var/datum/round_event/ion_storm/add_law_only/ion = new()
	ion.announce_chance = announce_ion_laws
	ion.ionMessage = input

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Add Custom AI Law") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/admin_call_shuttle()
	set category = "Admin.Events"
	set name = "Call Shuttle"

	if(EMERGENCY_AT_LEAST_DOCKED)
		return

	if(!check_rights(R_ADMIN))
		return

	var/confirm = tgui_alert(usr, "You sure?", "Confirm", list("Yes", "Yes (No Recall)", "No"))
	switch(confirm)
		if(null, "No")
			return
		if("Yes (No Recall)")
			SSshuttle.admin_emergency_no_recall = TRUE
			SSshuttle.emergency.mode = SHUTTLE_IDLE

	SSshuttle.emergency.request()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Call Shuttle") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_admin("[key_name(usr)] admin-called the emergency shuttle.")
	message_admins(span_adminnotice("[key_name_admin(usr)] admin-called the emergency shuttle[confirm == "Yes (No Recall)" ? " (non-recallable)" : ""]."))
	return

/client/proc/admin_cancel_shuttle()
	set category = "Admin.Events"
	set name = "Cancel Shuttle"
	if(!check_rights(0))
		return
	if(tgui_alert(usr, "You sure?", "Confirm", list("Yes", "No")) != "Yes")
		return

	if(SSshuttle.admin_emergency_no_recall)
		SSshuttle.admin_emergency_no_recall = FALSE

	if(EMERGENCY_AT_LEAST_DOCKED)
		return

	SSshuttle.emergency.cancel()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Cancel Shuttle") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_admin("[key_name(usr)] admin-recalled the emergency shuttle.")
	message_admins(span_adminnotice("[key_name_admin(usr)] admin-recalled the emergency shuttle."))

	return

/client/proc/admin_disable_shuttle()
	set category = "Admin.Events"
	set name = "Disable Shuttle"

	if(!check_rights(R_ADMIN))
		return

	if(SSshuttle.emergency.mode == SHUTTLE_DISABLED)
		to_chat(usr, span_warning("Error, shuttle is already disabled."))
		return

	if(tgui_alert(usr, "You sure?", "Confirm", list("Yes", "No")) != "Yes")
		return

	message_admins(span_adminnotice("[key_name_admin(usr)] disabled the shuttle."))

	SSshuttle.last_mode = SSshuttle.emergency.mode
	SSshuttle.last_call_time = SSshuttle.emergency.timeLeft(1)
	SSshuttle.admin_emergency_no_recall = TRUE
	SSshuttle.emergency.setTimer(0)
	SSshuttle.emergency.mode = SHUTTLE_DISABLED
	priority_announce("Warning: Emergency Shuttle uplink failure, shuttle disabled until further notice.", "Emergency Shuttle Uplink Alert", 'sound/misc/announce_dig.ogg')

/client/proc/admin_enable_shuttle()
	set category = "Admin.Events"
	set name = "Enable Shuttle"

	if(!check_rights(R_ADMIN))
		return

	if(SSshuttle.emergency.mode != SHUTTLE_DISABLED)
		to_chat(usr, span_warning("Error, shuttle not disabled."))
		return

	if(tgui_alert(usr, "You sure?", "Confirm", list("Yes", "No")) != "Yes")
		return

	message_admins(span_adminnotice("[key_name_admin(usr)] enabled the emergency shuttle."))
	SSshuttle.admin_emergency_no_recall = FALSE
	SSshuttle.emergency_no_recall = FALSE
	if(SSshuttle.last_mode == SHUTTLE_DISABLED) //If everything goes to shit, fix it.
		SSshuttle.last_mode = SHUTTLE_IDLE

	SSshuttle.emergency.mode = SSshuttle.last_mode
	if(SSshuttle.last_call_time < 10 SECONDS && SSshuttle.last_mode != SHUTTLE_IDLE)
		SSshuttle.last_call_time = 10 SECONDS //Make sure no insta departures.
	SSshuttle.emergency.setTimer(SSshuttle.last_call_time)
	priority_announce("Warning: Emergency Shuttle uplink reestablished, shuttle enabled.", "Emergency Shuttle Uplink Alert", 'sound/misc/announce_dig.ogg')

/client/proc/toggle_nuke(obj/machinery/nuclearbomb/N in GLOB.nuke_list)
	set category = "Admin.Events"
	set name = "Toggle Nuke"
	set popup_menu = FALSE
	if(!check_rights(R_DEBUG))
		return

	if(!N.timing)
		var/newtime = input(usr, "Set activation timer.", "Activate Nuke", "[N.timer_set]") as num|null
		if(!newtime)
			return
		N.timer_set = newtime
	N.toggle_nuke_safety()
	N.toggle_nuke_armed()

	log_admin("[key_name(usr)] [N.timing ? "activated" : "deactivated"] a nuke at [AREACOORD(N)].")
	message_admins("[ADMIN_LOOKUPFLW(usr)] [N.timing ? "activated" : "deactivated"] a nuke at [ADMIN_VERBOSEJMP(N)].")
	SSblackbox.record_feedback("nested tally", "admin_toggle", 1, list("Toggle Nuke", "[N.timing]")) //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/admin_change_sec_level()
	set category = "Admin.Events"
	set name = "Set Security Level"
	set desc = "Changes the security level. Announcement only, i.e. setting to Delta won't activate nuke"

	if(!check_rights(R_ADMIN))
		return

	var/level = tgui_input_list(usr, "Select Security Level:", "Set Security Level", SSsecurity_level.available_levels)

	if(!level)
		return

	SSsecurity_level.set_level(level)

	log_admin("[key_name(usr)] changed the security level to [level]")
	message_admins("[key_name_admin(usr)] changed the security level to [level]")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Set Security Level [capitalize(level)]") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/run_weather()
	set category = "Admin.Events"
	set name = "Run Weather"
	set desc = "Triggers a weather on the z-level you choose."

	if(!holder)
		return

	var/weather_type = input("Choose a weather", "Weather")  as null|anything in sort_list(subtypesof(/datum/weather), /proc/cmp_typepaths_asc)
	if(!weather_type)
		return

	var/turf/T = get_turf(mob)
	var/z_level = input("Z-Level to target?", "Z-Level", T?.z) as num|null
	if(!isnum(z_level))
		return

	SSweather.run_weather(weather_type, z_level)

	message_admins("[key_name_admin(usr)] started weather of type [weather_type] on the z-level [z_level].")
	log_admin("[key_name(usr)] started weather of type [weather_type] on the z-level [z_level].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Run Weather")

/client/proc/add_mob_ability()
	set category = "Admin.Events"
	set name = "Add Mob Ability"
	set desc = "Adds an ability to a marked mob."

	if(!holder)
		return

	if(!isliving(holder.marked_datum))
		to_chat(usr, span_warning("Error: Please mark a mob to add actions to it."))
		return

	var/mob/living/marked_mob = holder.marked_datum

	var/list/all_mob_actions = sort_list(subtypesof(/datum/action/cooldown/mob_cooldown), /proc/cmp_typepaths_asc)

	var/ability_type = tgui_input_list(usr, "Choose an ability", "Ability", all_mob_actions)

	if(!ability_type)
		return

	var/datum/action/cooldown/mob_cooldown/add_ability

	var/make_sequence = tgui_alert(usr, "Would you like this action to be a sequence of multiple abilities?", "Sequence Ability", list("Yes", "No"))
	if(make_sequence == "Yes")
		add_ability = new /datum/action/cooldown/mob_cooldown(marked_mob)
		add_ability.sequence_actions = list()
		while(!isnull(ability_type))
			var/ability_delay = tgui_input_number(usr, "Enter the delay in seconds before the next ability in the sequence is used", "Ability Delay", 2)
			if(isnull(ability_delay) || ability_delay < 0)
				ability_delay = 0
			add_ability.sequence_actions[ability_type] = ability_delay * 1 SECONDS
			ability_type = tgui_input_list(usr, "Choose a new sequence ability", "Sequence Ability", all_mob_actions)
		var/ability_cooldown = tgui_input_number(usr, "Enter the sequence abilities cooldown in seconds", "Ability Cooldown", 2)
		if(isnull(ability_cooldown) || ability_cooldown < 0)
			ability_cooldown = 2
		add_ability.cooldown_time = ability_cooldown * 1 SECONDS
		var/ability_melee_cooldown = tgui_input_number(usr, "Enter the abilities melee cooldown in seconds", "Melee Cooldown", 2)
		if(isnull(ability_melee_cooldown) || ability_melee_cooldown < 0)
			ability_melee_cooldown = 2
		add_ability.melee_cooldown_time = ability_melee_cooldown * 1 SECONDS
		add_ability.name = tgui_input_text(usr, "Choose ability name", "Ability name", "Generic Ability")
		add_ability.create_sequence_actions()
	else
		add_ability = new ability_type(marked_mob)

	if(isnull(marked_mob))
		return
	add_ability.Grant(marked_mob)

	message_admins("[key_name_admin(usr)] added mob ability [ability_type] to mob [marked_mob].")
	log_admin("[key_name(usr)] added mob ability [ability_type] to mob [marked_mob].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Add Mob Ability") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/remove_mob_ability()
	set category = "Admin.Events"
	set name = "Remove Mob Ability"
	set desc = "Removes an ability from marked mob."

	if(!holder)
		return

	if(!isliving(holder.marked_datum))
		to_chat(usr, span_warning("Error: Please mark a mob to remove actions from it."))
		return

	var/mob/living/marked_mob = holder.marked_datum

	var/list/all_mob_actions = list()
	for(var/datum/action/cooldown/mob_cooldown/ability in marked_mob.actions)
		all_mob_actions.Add(ability)

	var/datum/action/cooldown/mob_cooldown/ability = tgui_input_list(usr, "Remove an ability", "Ability", all_mob_actions)

	if(!ability)
		return

	var/ability_name = ability.name
	QDEL_NULL(ability)

	message_admins("[key_name_admin(usr)] removed ability [ability_name] from mob [marked_mob].")
	log_admin("[key_name(usr)] removed mob ability [ability_name] from mob [marked_mob].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Remove Mob Ability") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/**
 * Basically an easy access verb for admins to change religion names and stuff
 */
/client/proc/religious_vars()
	set name = "Modify Religions"
	set category = "Admin.Events"

	if(!check_rights(R_ADMIN))
		return
	if(tgui_alert(usr, "Note that these are set by the station's chaplain, messing with these will override what they have chosen.", "Notice", list("I know", "Oh shoot")) != "I know")
		return

	var/religion_name = tgui_input_text(usr, "Change global religion name", "Religion name", GLOB.religion)
	if(!religion_name)
		return
	// These logs are kind of meaningless since they could just modify the global vars,
	// but yknow it's the thought that counts.
	message_admins("[key_name_admin(usr)] changed global religion name from [GLOB.religion] to [religion_name].")
	log_admin("[key_name(usr)] changed global religion name from [GLOB.religion] to [religion_name].")
	GLOB.religion = religion_name

	var/new_god = tgui_input_text(usr, "Change global deity name", "Deity name", GLOB.deity)
	if(!new_god)
		return
	message_admins("[key_name_admin(usr)] changed global deity from [GLOB.diety] to [new_god].")
	log_admin("[key_name(usr)] changed global deity from [GLOB.diety] to [new_god].")
	GLOB.diety = new_god

	var/new_bible = tgui_input_text(usr, "Change global bible name", "Bible name", GLOB.bible_name)
	if(!new_bible)
		return
	message_admins("[key_name_admin(usr)] changed global bible name from [GLOB.bible_name] to [new_bible].")
	log_admin("[key_name(usr)] changed global bible name from [GLOB.bible_name] to [new_bible].")
	GLOB.bible_name = new_bible

	if(GLOB.holy_weapon_type)
		var/reset_nullrod = tgui_alert(usr, "Reset picked Null Rod varient? Existing ones remain unchanged", "Null rod", list("Yes", "No"))
		if(reset_nullrod == "Yes")
			message_admins("[key_name_admin(usr)] reset the picked null rod varient.")
			log_admin("[key_name(usr)] reset the picked null rod varient.")
			GLOB.holy_weapon_type = null
		else if(isnull(reset_nullrod))
			return

	if(GLOB.holy_armor_type)
		var/reset_armor = tgui_alert(usr, "Reset picked Holy Armor varient? Existing ones remain unchanged", "Holy Armor", list("Yes", "No"))
		if(reset_nullrod == "Yes")
			message_admins("[key_name_admin(usr)] reset the picked holy armor varient.")
			log_admin("[key_name(usr)] reset the picked holy armor varient.")
			GLOB.holy_armor_type = null
		else if(isnull(reset_nullrod))
			return

	if(GLOB.current_bible_skin)
		var/reset_bible = tgui_alert(usr, "Reset picked Bible varient? Existing ones remain unchanged", "Bible Skin", list("Yes", "No"))
		if(reset_bible == "Yes")
			message_admins("[key_name_admin(usr)] reset the picked bible varient.")
			log_admin("[key_name(usr)] reset the picked bible varient.")
			GLOB.current_bible_skin = null
		else if(isnull(reset_bible))
			return
