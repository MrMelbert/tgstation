/datum/action/cooldown/spell/cult_commune
	name = "Communion"
	desc = "Whispered words that all cultists can hear.<br><b>Warning:</b> Nearby non-cultists can still hear you!"
	DEFINE_CULT_ACTION("cult_comms", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "O bidai nabora se sma!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	/// The message of the chant, set in before cast, used in cast, and reset in after cast
	var/next_message

/datum/action/cooldown/spell/cult_commune/can_cast_spell(feedback)
	// Hard requirement for cult as it requires a team to talk to
	return ..() && IS_CULTIST(owner)

/datum/action/cooldown/spell/cult_commune/is_valid_target(atom/cast_on)
	return ismob(cast_on)

/datum/action/cooldown/spell/cult_commune/before_cast(mob/cast_on)
	. = ..()
	if(next_message)
		return

	next_message = tgui_input_text(cast_on, "Message to tell to the other acolytes", "Voice of Blood", encode = FALSE)
	if(!next_message || QDELETED(src) || QDELETED(cast_on) || !IsAvailable())
		return . | SPELL_CANCEL_CAST

	var/list/filter_result = CAN_BYPASS_FILTER(cast_on) ? null : is_ic_filtered(next_message)
	if(filter_result)
		REPORT_CHAT_FILTER_TO_USER(cast_on, filter_result)
		return . | SPELL_CANCEL_CAST

	var/list/soft_filter_result = CAN_BYPASS_FILTER(cast_on) ? null : is_soft_ic_filtered(next_message)
	if(soft_filter_result)
		if(tgui_alert(cast_on, "Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return . | SPELL_CANCEL_CAST
		message_admins("[ADMIN_LOOKUPFLW(cast_on)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[html_encode(next_message)]\"")
		log_admin_private("[key_name(cast_on)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[next_message]\"")

/datum/action/cooldown/spell/cult_commune/cast(mob/cast_on)
	. = ..()
	next_message = html_encode(next_message)
	if(next_message)
		cultist_commune(cast_on, next_message)

/datum/action/cooldown/spell/cult_commune/after_cast(atom/cast_on)
	. = ..()
	next_message = null

/datum/action/cooldown/spell/cult_commune/proc/cultist_commune(mob/living/user, message)
	user.whisper(message, filterproof = TRUE) // filterproof. already checked
	var/title = "Acolyte"
	var/span = "cult italic"
	if(IS_CULTIST_MASTER(user))
		title = "Master"
		span = "cultlarge"
	else if(!ishuman(user))
		title = "Construct"

	var/my_message = "<span class='[span]'><b>[title] [findtextEx(user.name, user.real_name) ? user.name : "[user.real_name] (as [user.name])"]:</b> [message]</span>"
	for(var/mob/player as anything in GLOB.player_list)
		if(IS_CULTIST(player))
			to_chat(player, my_message)

		else if(isobserver(player))
			var/link = FOLLOW_LINK(player, user)
			to_chat(player, "[link] [my_message]")

	user.log_talk(message, LOG_SAY, tag = "cult")

/datum/action/cooldown/spell/cult_commune/spirit
	name = "Spiritual Communion"
	desc = "Conveys a message from the spirit realm that all cultists can hear."

/datum/action/cooldown/spell/cult_commune/spirit/is_valid_target(atom/cast_on)
	return isdead(cast_on) || isshade(cast_on) // I guess

/datum/action/cooldown/spell/cult_commune/spirit/cultist_commune(mob/living/user, message)
	var/my_message = span_cultboldtalic("The [user.name]: [message]")
	for(var/mob/player_list as anything in GLOB.player_list)
		if(IS_CULTIST(player_list))
			to_chat(player_list, my_message)
		else if(isobserver(player_list))
			var/link = FOLLOW_LINK(player_list, user)
			to_chat(player_list, "[link] [my_message]")
