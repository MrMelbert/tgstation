/obj/item/soulstone
	name = "soulstone shard"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "soulstone"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	layer = HIGH_OBJ_LAYER
	desc = "A fragment of the legendary treasure known simply as the 'Soul Stone'. The shard still flickers with a fraction of the full artefact's power."
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_BELT
	/// if TRUE, we can only be used once.
	var/one_use = FALSE
	/// Only used if one_use is TRUE. Whether it's used.
	var/spent = FALSE
	/// if TRUE, our soulstone will work on mobs which are in crit. if FALSE, the mob must be dead.
	var/grab_sleeping = TRUE
	/// This controls the color of the soulstone as well as restrictions for who can use it.
	/// This controls the color of the soulstone as well as restrictions for who can use it. THEME_CULT is red and is the default of cultist THEME_WIZARD is purple and is the default of wizard and THEME_HOLY is for purified soul stone
	/// THEME_CULT is red and is the default of cultist
	/// THEME_WIZARD is purple and is the default of wizard
	/// THEME_HOLY is for purified soul stone
	var/theme = THEME_CULT
	/// Role check, if any needed
	var/required_role = /datum/antagonist/cult

/obj/item/soulstone/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/exorcisable, \
			pre_exorcism_callback = CALLBACK(src, .proc/pre_exorcism), \
			on_exorcism_callback = CALLBACK(src, .proc/on_exorcism))

/obj/item/soulstone/update_appearance(updates)
	. = ..()
	for(var/mob/living/simple_animal/shade/sharded_shade in src)
		switch(theme)
			if(THEME_HOLY)
				sharded_shade.name = "Purified [sharded_shade.real_name]"
				sharded_shade.icon_state = "shade_holy"
				sharded_shade.loot = list(/obj/item/ectoplasm/angelic)
			if(THEME_CULT)
				sharded_shade.name = sharded_shade.real_name
				sharded_shade.icon_state = "shade_cult"
				sharded_shade.loot = list(/obj/item/ectoplasm)
			if(THEME_WIZARD)
				sharded_shade.name = sharded_shade.real_name
				sharded_shade.icon_state = "shade_wizard"
				sharded_shade.loot = list(/obj/item/ectoplasm/mystic)

/obj/item/soulstone/update_icon_state()
	. = ..()
	switch(theme)
		if(THEME_HOLY)
			icon_state = "purified_soulstone"
		if(THEME_CULT)
			icon_state = "soulstone"
		if(THEME_WIZARD)
			icon_state = "mystic_soulstone"

	if(contents.len)
		icon_state = "[icon_state]2"

/obj/item/soulstone/update_name(updates)
	. = ..()
	if(spent)
		name = "dull [name]"
		return

	var/mob/living/simple_animal/shade/shade = locate() in src
	if(shade)
		name = "[name]: [shade.real_name]"
	else
		name = initial(name)

/obj/item/soulstone/update_desc(updates)
	. = ..()
	if(spent)
		desc = "A fragment of the legendary treasure known simply as \
			the 'Soul Stone'. The shard lies still, dull and lifeless; \
			whatever spark it once held long extinguished."

/obj/item/soulstone/proc/pre_exorcism(mob/exorcist)
	if(IS_CULTIST(exorcist) || theme == THEME_HOLY)
		return STOP_EXORCISM

/obj/item/soulstone/proc/on_exorcism(mob/living/exorcist)
	required_role = null
	theme = THEME_HOLY
	update_appearance()
	for(var/mob/shade_to_deconvert in contents)
		shade_to_deconvert.mind?.remove_antag_datum(/datum/antagonist/cult)

	exorcist.visible_message(span_notice("[exorcist] purifies [src]!"))
	return TRUE

/**
 * corrupt: turns the soulstone into a cult one and turns the occupant shade, if any, into a cultist
 */
/obj/item/soulstone/proc/corrupt()
	if(theme == THEME_CULT)
		return FALSE

	required_role = /datum/antagonist/cult
	theme = THEME_CULT
	update_appearance()
	for(var/mob/shade_to_convert in contents)
		if(IS_CULTIST(shade_to_convert))
			continue
		shade_to_convert.mind?.add_antag_datum(/datum/antagonist/cult)

	return TRUE

/obj/item/soulstone/proc/role_check(mob/who)
	if(theme == THEME_HOLY)
		if(!who.mind)
			return FALSE

		return who.mind.holy_role

	if(!required_role)
		return TRUE

	return who.mind?.has_antag_datum(required_role)

/obj/item/soulstone/proc/role_check_with_side_effects(mob/who)
	if(role_check(who))
		return TRUE

	if(!isliving(who))
		return FALSE

	if(theme == THEME_HOLY)
		if(!IS_CULTIST(who))
			return FALSE

		to_chat(who, span_userdanger("Holy magics residing in \the [src] burn your hand!"))

		var/mob/living/living_user = who
		var/obj/item/bodypart/affecting = living_user.get_active_hand()
		affecting.receive_damage(burn = 10)
		living_user.emote("scream")
		living_user.dropItemToGround(src)

	else
		to_chat(who, span_userdanger("Your body is wracked with debilitating pain!"))

		var/mob/living/living_user = who
		living_user.Unconscious(10 SECONDS)

	return FALSE

/// Called whenever the soulstone releases a shade from it.
/obj/item/soulstone/proc/on_release_spirits()
	if(!one_use)
		return

	spent = TRUE
	update_appearance()

/obj/item/soulstone/pickup(mob/living/user)
	. = ..()
	if(role_check(user))
		return

	to_chat(user, span_warning("An overwhelming feeling of dread comes over you as you pick up [src]."))

/obj/item/soulstone/examine(mob/user)
	. = ..()
	if(role_check(user) || isobserver(user))
		if(grab_sleeping)
			. += span_cult("A soulstone, used to capture souls, either from unconscious or sleeping humans or from freed shades.")
		else
			. += span_cult("A soulstone, used to capture a soul, either from dead humans or from freed shades.")

		. += span_cult("The captured soul can be placed into a construct shell to produce a construct, or released from the stone as a shade.")
		if(spent)
			. += span_cult("This shard is spent; it is now just a creepy rock.")

/obj/item/soulstone/Destroy() //Stops the shade from being qdel'd immediately and their ghost being sent back to the arrival shuttle.
	for(var/mob/living/simple_animal/shade/shade in src)
		INVOKE_ASYNC(shade, /mob/living/proc/death)
	return ..()

/obj/item/soulstone/attack_self(mob/living/user)
	. = ..()
	if(.)
		return TRUE
	if(!in_range(src, user))
		return
	if(!role_check_with_side_effects(user))
		return TRUE
	if(contents.len)
		release_shades(user)
		return TRUE

/obj/item/soulstone/proc/release_shades(mob/user, silent = FALSE)
	for(var/mob/living/simple_animal/shade/captured_shade in src)
		captured_shade.forceMove(get_turf(user))
		captured_shade.cancel_camera()
		update_appearance()
		if(!silent)
			if(IS_CULTIST(user))
				to_chat(captured_shade, span_bold("You have been released from your prison, \
					but you are still bound to the cult's will. Help them succeed in their goals at all costs."))

			else if(role_check(user))
				to_chat(captured_shade, span_bold("You have been released from your prison, \
					but you are still bound to [user.real_name]'s will. Help [user.p_them()] succeed in \
					[user.p_their()] goals at all costs."))

		on_release_spirits()

/obj/item/soulstone/pre_attack(atom/hit_atom, mob/living/user, params)
	. = ..()
	if(.)
		return TRUE

	if(!role_check_with_side_effects(user))
		return TRUE

	if(SEND_SIGNAL(hit_atom, COMSIG_SOULSTONE_HIT, src, user) & SOULSTONE_HIT_HANDLED)
		return TRUE

	if(!ishuman(hit_atom) || hit_atom == user)
		return FALSE // continue attack chain

	if(spent)
		to_chat(user, span_warning("There is no power left in [src]."))
		return TRUE

	var/mob/living/carbon/human/human_hit = hit_atom
	if(IS_CULTIST(human_hit) && IS_CULTIST(user))
		to_chat(user, span_cultlarge("\"Come now, do not capture your bretheren's soul.\""))
		return TRUE

	log_combat(user, human_hit, "captured [human_hit.name]'s soul", src)
	capture_soul(human_hit, user)
	return TRUE

///////////////////////////Transferring to constructs/////////////////////////////////////////////////////
/obj/structure/construct_shell
	name = "empty shell"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "construct_cult"
	desc = "A wicked machine used by those skilled in magical arts. It is inactive."

/obj/structure/construct_shell/examine(mob/user)
	. = ..()
	if(IS_CULTIST(user) || IS_WIZARD(user) || isobserver(user) || user.mind?.holy_role)
		. += {"<span class='cult'>A construct shell, used to house bound souls from a soulstone.\n
		Placing a soulstone with a soul into this shell allows you to produce your choice of the following:\n
		An <b>Artificer</b>, which can produce <b>more shells and soulstones</b>, as well as fortifications.\n
		A <b>Wraith</b>, which does high damage and can jaunt through walls, though it is quite fragile.\n
		A <b>Juggernaut</b>, which is very hard to kill and can produce temporary walls, but is slow.</span>"}

/obj/structure/construct_shell/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_SOULSTONE_HIT, .proc/on_soulstone_hit)

/obj/structure/construct_shell/proc/on_soulstone_hit(datum/source, obj/item/soulstone/soulstone, mob/living/user)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, .proc/transfer_to_construct, soulstone, user)
	return SOULSTONE_HIT_HANDLED

/obj/structure/construct_shell/proc/transfer_to_construct(obj/item/soulstone/soulstone, mob/living/user)
	var/mob/living/simple_animal/shade/shade = locate() in src
	if(!shade)
		to_chat(user, "[span_userdanger("Creation failed!")]: [soulstone] is empty! Go kill someone!")
		return FALSE

	var/construct_class = show_radial_menu(user, src, GLOB.construct_radial_images, custom_check = CALLBACK(src, .proc/check_menu, soulstone, user), require_near = TRUE, tooltips = TRUE)
	if(QDELETED(src) || !construct_class)
		return FALSE

	shade.mind?.remove_antag_datum(/datum/antagonist/cult)
	make_new_construct_from_class(construct_class, soulstone.theme, shade, user, FALSE, loc)
	qdel(soulstone)
	qdel(src)
	return TRUE

/obj/structure/construct_shell/proc/check_menu(obj/item/soulstone/soulstone, mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.is_holding(soulstone) || !user.CanReach(src, soulstone))
		return FALSE
	if(!soulstone.role_check(user))
		return FALSE
	return TRUE

/// Procs for moving soul in and out off stone

/// Transfer the mind of a carbon mob (which is then dusted) into a shade mob inside src.
/// If forced, sacrifical and stat checks are skipped.
/obj/item/soulstone/proc/capture_soul(mob/living/carbon/victim, mob/user, forced = FALSE)
	if(!iscarbon(victim)) //TODO: Add sacrifice stoning for non-organics, just because you have no body doesnt mean you dont have a soul
		return FALSE
	if(contents.len)
		return FALSE

	if(!forced)
		var/datum/antagonist/cult/cultist = IS_CULTIST(user)
		if(cultist)
			var/datum/team/cult/cult_team = cultist.get_team()
			if(victim.mind && cult_team.is_sacrifice_target(victim.mind))
				to_chat(user, span_cult("<b>\"This soul is mine.</b></span> <span class='cultlarge'>SACRIFICE THEM!\""))
				return FALSE

		if(grab_sleeping ? victim.stat == CONSCIOUS : victim.stat != DEAD)
			to_chat(user, "[span_userdanger("Capture failed!")]: Kill or maim the victim first!")
			return FALSE

	victim.grab_ghost()
	if(victim.client)
		init_shade(victim, user)
		return TRUE

	to_chat(user, "[span_userdanger("Capture failed!")]: The soul has already fled its mortal frame. You attempt to bring it back...")
	INVOKE_ASYNC(src, .proc/get_ghost_to_replace_shade, victim, user)
	return TRUE //it'll probably get someone

/**
 * Creates a new shade mob to inhabit the stone.
 *
 * victim - the body that's being shaded
 * user - the person doing the shading. Optional.
 * message_user - if TRUE, we send the user (if present) a message that a shade has been created / captured.
 * shade_controller - the mob (usually, a ghost) that will take over control of the victim / new shade. Optional, if not passed the victim itself will take control.
 */
/obj/item/soulstone/proc/init_shade(mob/living/carbon/human/victim, mob/user, message_user = FALSE, mob/shade_controller)
	if(!shade_controller)
		shade_controller = victim
	victim.stop_sound_channel(CHANNEL_HEARTBEAT)
	var/mob/living/simple_animal/shade/soulstone_spirit = new /mob/living/simple_animal/shade(src)
	soulstone_spirit.AddComponent(/datum/component/soulstoned, src)
	soulstone_spirit.name = "Shade of [victim.real_name]"
	soulstone_spirit.real_name = "Shade of [victim.real_name]"
	soulstone_spirit.key = shade_controller.key
	soulstone_spirit.copy_languages(victim, LANGUAGE_MIND)//Copies the old mobs languages into the new mob holder.
	if(user)
		soulstone_spirit.copy_languages(user, LANGUAGE_MASTER)
	soulstone_spirit.update_atom_languages()
	soulstone_spirit.grant_all_languages(FALSE, FALSE, TRUE) //Grants omnitongue
	if(user)
		soulstone_spirit.faction |= "[REF(user)]" //Add the master as a faction, allowing inter-mob cooperation
		if(IS_CULTIST(user))
			soulstone_spirit.mind.add_antag_datum(/datum/antagonist/cult)

	soulstone_spirit.cancel_camera()
	update_appearance()
	if(user)
		if(IS_CULTIST(user))
			to_chat(soulstone_spirit, span_bold("Your soul has been captured! \
				You are now bound to the cult's will. Help them succeed in their goals at all costs."))
		else if(role_check(user))
			to_chat(soulstone_spirit, span_bold("Your soul has been captured! You are now bound to [user.real_name]'s will. \
				Help [user.p_them()] succeed in [user.p_their()] goals at all costs."))
		if(message_user)
			to_chat(user, "[span_info("<b>Capture successful!</b>:")] [victim.real_name]'s soul has been ripped \
				from [victim.p_their()] body and stored within [src].")

	victim.dust(drop_items = TRUE)

/**
 * Gets a ghost from dead chat to replace a missing player when a shade is created.
 *
 * Gets ran if a soulstone is used on a body that has no client to take over the shade.
 *
 * victim - the body that's being shaded
 * user - the mob shading the body
 *
 * Returns FALSE if no ghosts are available or the replacement fails.
 * Returns TRUE otherwise.
 */
/obj/item/soulstone/proc/get_ghost_to_replace_shade(mob/living/carbon/victim, mob/user)
	var/mob/dead/observer/chosen_ghost
	var/list/consenting_candidates = poll_ghost_candidates("Would you like to play as a Shade?", "Cultist", ROLE_CULTIST, 5 SECONDS, POLL_IGNORE_SHADE)
	if(length(consenting_candidates))
		chosen_ghost = pick(consenting_candidates)

	if(!victim || user.incapacitated() || !user.is_holding(src) || !user.CanReach(victim, src))
		return FALSE
	if(!chosen_ghost || !chosen_ghost.client)
		to_chat(user, span_danger("There were no spirits willing to become a shade."))
		return FALSE
	if(contents.len) //If they used the soulstone on someone else in the meantime
		return FALSE
	to_chat(user, "[span_info("<b>Capture successful!</b>:")] A spirit has entered [src], \
		taking upon the identity of [victim].")
	init_shade(victim, user, shade_controller = chosen_ghost)
	return TRUE

/proc/make_new_construct_from_class(construct_class, theme, mob/target, mob/creator, cultoverride, loc_override)
	switch(construct_class)
		if(CONSTRUCT_JUGGERNAUT)
			if(IS_CULTIST(creator))
				makeNewConstruct(/mob/living/simple_animal/hostile/construct/juggernaut, target, creator, cultoverride, loc_override) // ignore themes, the actual giving of cult info is in the makeNewConstruct proc
				return
			switch(theme)
				if(THEME_WIZARD)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/juggernaut/mystic, target, creator, cultoverride, loc_override)
				if(THEME_HOLY)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/juggernaut/angelic, target, creator, cultoverride, loc_override)
				if(THEME_CULT)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/juggernaut/noncult, target, creator, cultoverride, loc_override)
		if(CONSTRUCT_WRAITH)
			if(IS_CULTIST(creator))
				makeNewConstruct(/mob/living/simple_animal/hostile/construct/wraith, target, creator, cultoverride, loc_override) // ignore themes, the actual giving of cult info is in the makeNewConstruct proc
				return
			switch(theme)
				if(THEME_WIZARD)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/wraith/mystic, target, creator, cultoverride, loc_override)
				if(THEME_HOLY)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/wraith/angelic, target, creator, cultoverride, loc_override)
				if(THEME_CULT)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/wraith/noncult, target, creator, cultoverride, loc_override)
		if(CONSTRUCT_ARTIFICER)
			if(IS_CULTIST(creator))
				makeNewConstruct(/mob/living/simple_animal/hostile/construct/artificer, target, creator, cultoverride, loc_override) // ignore themes, the actual giving of cult info is in the makeNewConstruct proc
				return
			switch(theme)
				if(THEME_WIZARD)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/artificer/mystic, target, creator, cultoverride, loc_override)
				if(THEME_HOLY)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/artificer/angelic, target, creator, cultoverride, loc_override)
				if(THEME_CULT)
					makeNewConstruct(/mob/living/simple_animal/hostile/construct/artificer/noncult, target, creator, cultoverride, loc_override)

/proc/makeNewConstruct(mob/living/simple_animal/hostile/construct/ctype, mob/target, mob/stoner = null, cultoverride = FALSE, loc_override = null)
	if(QDELETED(target))
		return
	var/mob/living/simple_animal/hostile/construct/newstruct = new ctype((loc_override) ? (loc_override) : (get_turf(target)))
	var/makeicon = newstruct.icon_state
	var/theme = newstruct.theme
	flick("make_[makeicon][theme]", newstruct)
	playsound(newstruct, 'sound/effects/constructform.ogg', 50)
	if(stoner)
		newstruct.faction |= "[REF(stoner)]"
		newstruct.master = stoner
		var/datum/action/innate/seek_master/SM = new()
		SM.Grant(newstruct)
	newstruct.key = target.key
	var/atom/movable/screen/alert/bloodsense/BS
	if(newstruct.mind && ((stoner && IS_CULTIST(stoner)) || cultoverride) && SSticker?.mode)
		newstruct.mind.add_antag_datum(/datum/antagonist/cult)
	if(IS_CULTIST(stoner) || cultoverride)
		to_chat(newstruct, "<b>You are still bound to serve the cult[stoner ? " and [stoner]":""], follow [stoner ? stoner.p_their() : "their"] orders and help [stoner ? stoner.p_them() : "them"] complete [stoner ? stoner.p_their() : "their"] goals at all costs.</b>")
	else if(stoner)
		to_chat(newstruct, "<b>You are still bound to serve your creator, [stoner], follow [stoner.p_their()] orders and help [stoner.p_them()] complete [stoner.p_their()] goals at all costs.</b>")
	newstruct.clear_alert("bloodsense")
	BS = newstruct.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(BS)
		BS.Cviewer = newstruct
	newstruct.cancel_camera()

/obj/item/soulstone/anybody
	required_role = null

/obj/item/soulstone/mystic
	icon_state = "mystic_soulstone"
	theme = THEME_WIZARD
	required_role = /datum/antagonist/wizard

/obj/item/soulstone/anybody/revolver
	one_use = TRUE
	grab_sleeping = FALSE

/obj/item/soulstone/anybody/purified
	icon_state = "purified_soulstone"
	theme = THEME_HOLY

/obj/item/soulstone/anybody/chaplain
	name = "mysterious old shard"
	one_use = TRUE
	grab_sleeping = FALSE

/obj/item/soulstone/anybody/chaplain/sparring
	name = "divine punishment"
	desc = "A prison for those who lost a divine game."
	icon_state = "purified_soulstone"
	theme = THEME_HOLY

/obj/item/soulstone/anybody/chaplain/sparring/Initialize(mapload)
	. = ..()
	name = "[GLOB.deity]'s punishment"
	desc = "A prison for those who lost [GLOB.deity]'s game."

/obj/item/soulstone/anybody/mining
	grab_sleeping = FALSE
