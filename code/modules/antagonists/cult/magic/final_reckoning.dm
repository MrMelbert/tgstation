/datum/action/cooldown/spell/final_reckoning
	name = "Final Reckoning"
	desc = "A single-use spell that brings the entire cult to the master's location."
	DEFINE_CULT_ACTION("sintouch", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation_type = INVOCATION_NONE
	cooldown_time = 16 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	default_button_position = DEFAULT_UNIQUE_BLOODSPELLS

/datum/action/cooldown/spell/final_reckoning/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	if(GLOB.cult_narsie)
		return FALSE
	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	if(!cult_team || cult_team.reckoning_complete)
		return FALSE

	return TRUE

/datum/action/cooldown/spell/final_reckoning/cast(atom/cast_on)
	. = ..()

	StartCooldown()
	var/datum/team/cult/cult_team = GET_CULT_TEAM(owner)
	var/area/place = get_area(owner)
	// cant do final reckoning in the summon area to prevent abuse, you'll need to get everyone to stand on the circle!
	if(place in cult_team.ritual_sites)
		to_chat(owner, span_cultlarge("The veil is too weak here! Move to an area where it is strong enough to support this magic."))
		return

	for(var/i in 1 to 4)
		var/list/destinations = list()
		for(var/turf/nearby in orange(1, owner))
			if(!nearby.is_blocked_turf(TRUE))
				destinations += nearby
		if(!length(destinations))
			to_chat(owner, span_warning("You need more space to summon your cult!"))
			return

		chant(i)
		if(!do_after(owner, 3 SECONDS))
			return
		if(QDELETED(src) || QDELETED(owner) || !IS_CULTIST(owner))
			return

		for(var/obj/effect/blessing/begone_ye in range(1, owner))
			qdel(begone_ye)

		for(var/datum/mind/team_member as anything in cult_team.members)
			if(!isliving(team_member.current) || team_member.current.stat == DEAD)
				continue
			teleport(team_member.current, destinations, i)

	cult_team.reckoning_complete = TRUE

/datum/action/cooldown/spell/final_reckoning/proc/chant(chant_number)
	switch(chant_number)
		if(1)
			owner.say("C'arta forbici!", language = /datum/language/common, forced = "cult invocation")
		if(2)
			owner.say("Pleggh e'ntrath!", language = /datum/language/common, forced = "cult invocation")
			playsound(get_turf(owner), 'sound/magic/clockwork/narsie_attack.ogg', 50, TRUE)
		if(3)
			owner.say("Barhah hra zar'garis!", language = /datum/language/common, forced = "cult invocation")
			playsound(get_turf(owner), 'sound/magic/clockwork/narsie_attack.ogg', 75, TRUE)
		if(4)
			owner.say("N'ath reth sh'yro eth d'rekkathnor!!!", language = /datum/language/common, forced = "cult invocation")
			playsound(get_turf(owner), 'sound/magic/clockwork/narsie_attack.ogg', 100, TRUE)

/datum/action/cooldown/spell/final_reckoning/proc/teleport(mob/living/cultist, list/destinations, teleport_number)
	var/turf/mobloc = get_turf(cultist)
	switch(teleport_number)
		if(1)
			new /obj/effect/temp_visual/cult/sparks(mobloc, cultist.dir)
			playsound(mobloc, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

		if(2)
			new /obj/effect/temp_visual/dir_setting/cult/phase/out(mobloc, cultist.dir)
			playsound(mobloc, SFX_SPARKS, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

		if(3)
			new /obj/effect/temp_visual/dir_setting/cult/phase(mobloc, cultist.dir)
			playsound(mobloc, SFX_SPARKS, 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

		if(4)
			playsound(mobloc, 'sound/magic/exit_blood.ogg', 100, TRUE)
			if(cultist == owner)
				return
			var/turf/final = pick(destinations)
			new /obj/effect/temp_visual/cult/blood(final)
			addtimer(CALLBACK(src, PROC_REF(reckon), cultist, final), 1 SECONDS)

/datum/action/cooldown/spell/final_reckoning/proc/reckon(mob/living/cultist, turf/final)
	if(istype(cultist.loc, /obj/item/soulstone))
		var/obj/item/soulstone/prison = cultist.loc
		prison.release_shades(owner)

	new /obj/effect/temp_visual/cult/blood/out(get_turf(cultist))
	cultist.setDir(SOUTH)
	do_teleport(cultist, final, channel = TELEPORT_CHANNEL_CULT)
