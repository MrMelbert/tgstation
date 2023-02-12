/datum/action/cooldown/spell/cult_commune
	name = "Communion"
	desc = "Whispered words that all cultists can hear.<br><b>Warning:</b>Nearby non-cultists can still hear you."
	DEFINE_CULT_ACTION("cult_comms", 'icons/mob/actions/actions_cult.dmi')

	invocation = "O bidai nabora se sma!"
	invocation_type = INVOCATION_WHISPER
	cooldown_time = 0 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

/datum/action/cooldown/spell/cult_commune/can_cast_spell(feedback)
	return ..() && IS_CULTIST(owner)

/datum/action/cooldown/spell/cult_commune/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/cult_commune/cast(mob/cast_on)
	. = ..()
	var/input = tgui_input_text(cast_on, "Message to tell to the other acolytes", "Voice of Blood")
	if(!input || !IsAvailable(feedback = TRUE) || QDELETED(src) || QDELETED(cast_on))
		return

	var/list/filter_result = CAN_BYPASS_FILTER(cast_on) ? null : is_ic_filtered(input)
	if(filter_result)
		REPORT_CHAT_FILTER_TO_USER(cast_on, filter_result)
		return

	var/list/soft_filter_result = CAN_BYPASS_FILTER(cast_on) ? null : is_soft_ic_filtered(input)
	if(soft_filter_result)
		if(tgui_alert(cast_on, "Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(cast_on)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[html_encode(input)]\"")
		log_admin_private("[key_name(cast_on)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[input]\"")
	cultist_commune(cast_on, input)

/datum/action/cooldown/spell/cult_commune/proc/cultist_commune(mob/living/user, message)
	var/final_message = html_decode(message)
	if(!final_message)
		return
	user.whisper(final_message, filterproof = TRUE) // filterproof. already checked
	var/title = "Acolyte"
	var/span = "cult italic"
	if(IS_CULTIST_MASTER(user))
		title = "Master"
		span = "cultlarge"
	else if(!ishuman(user))
		title = "Construct"

	var/my_message = "<span class='[span]'><b>[title] [findtextEx(user.name, user.real_name) ? user.name : "[user.real_name] (as [user.name])"]:</b> [final_message]</span>"
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
	if(!message)
		return
	var/my_message = span_cultboldtalic("The [user.name]: [message]")
	for(var/mob/player_list as anything in GLOB.player_list)
		if(IS_CULTIST(player_list))
			to_chat(player_list, my_message)
		else if(isobserver(player_list))
			var/link = FOLLOW_LINK(player_list, user)
			to_chat(player_list, "[link] [my_message]")
