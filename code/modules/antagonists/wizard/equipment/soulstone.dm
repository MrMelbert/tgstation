/obj/item/soulstone
	name = "soulstone shard"
	desc = "A fragment of the legendary treasure known simply as the 'Soul Stone'. \
		The shard still flickers with a fraction of the full artefact's power."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "soulstone"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	layer = HIGH_OBJ_LAYER
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_BELT
	/// if TRUE, we can only be used once.
	var/one_use = FALSE
	/// Only used if one_use is TRUE. Whether it's used.
	var/spent = FALSE
	/// if TRUE, our soulstone will work on mobs which are in crit. if FALSE, the mob must be dead.
	var/grab_sleeping = TRUE
	/// This controls the color of the soulstone as well as restrictions for who can use it.
	/// THEME_CULT is red and is the default of cultist
	/// THEME_WIZARD is purple and is the default of wizard
	/// THEME_HOLY is for purified soul stone
	var/theme = THEME_CULT
	/// Role check, if any needed
	var/required_role = /datum/antagonist/cult

	var/mob/living/simple_animal/shade/captured_shade

/obj/item/soulstone/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/exorcisable, \
		pre_exorcism_callback = CALLBACK(src, .proc/pre_exorcism), \
		on_exorcism_callback = CALLBACK(src, .proc/on_exorcism))

/obj/item/soulstone/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == captured_shade)
		captured_shade = null

// We'll shamelessly use update_appearance to also handle updating the shade inside depending on what theme we are
/obj/item/soulstone/update_appearance(updates)
	. = ..()
	if(captured_shade)
		update_shade()

/obj/item/soulstone/proc/update_shade()

	switch(theme)
		if(THEME_HOLY)
			captured_shade.name = "Purified [captured_shade.real_name]"
			captured_shade.icon_state = "shade_holy"
			captured_shade.loot = list(/obj/item/ectoplasm/angelic)
		if(THEME_CULT)
			captured_shade.name = captured_shade.real_name
			captured_shade.icon_state = "shade_cult"
			captured_shade.loot = list(/obj/item/ectoplasm)
		if(THEME_WIZARD)
			captured_shade.name = captured_shade.real_name
			captured_shade.icon_state = "shade_wizard"
			captured_shade.loot = list(/obj/item/ectoplasm/mystic)

/obj/item/soulstone/update_icon_state()
	. = ..()
	switch(theme)
		if(THEME_HOLY)
			icon_state = "purified_soulstone"
		if(THEME_CULT)
			icon_state = "soulstone"
		if(THEME_WIZARD)
			icon_state = "mystic_soulstone"

	if(captured_shade)
		icon_state = "[icon_state]2"

/obj/item/soulstone/update_name(updates)
	. = ..()
	if(spent)
		name = "dull [name]"
	else if(captured_shade)
		name = "[name]: [captured_shade.real_name]"
	else
		name = initial(name)

/obj/item/soulstone/update_desc(updates)
	. = ..()
	if(spent)
		desc = "A fragment of the legendary treasure known simply as \
			the 'Soul Stone'. The shard lies still, dull and lifeless; \
			whatever spark it once held long extinguished."

/// Callback for the exorcisable component
/// If we're holy, or the exorcist is a cultist, we shouldn't continue
/obj/item/soulstone/proc/pre_exorcism(mob/exorcist)
	if(IS_CULTIST(exorcist) || theme == THEME_HOLY)
		return STOP_EXORCISM

/// Callback for the exorcisable component
/// When we're exorcised, we become a holy shard and deconvert any shade inside
/obj/item/soulstone/proc/on_exorcism(mob/living/exorcist)
	required_role = null
	theme = THEME_HOLY
	update_appearance()
	assign_master(captured_shade, exorcist)
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

	if(captured_shade?.mind && !IS_CULTIST(captured_shade))
		captured_shade.mind.add_antag_datum(/datum/antagonist/cult)

	return TRUE

/// Checks if the passed mob is able to use the soulstone.
/// Checks required_role, or if we're holy, checks if we're a holy figure
/obj/item/soulstone/proc/role_check(mob/who)
	if(theme == THEME_HOLY)
		if(!who.mind)
			return FALSE

		return who.mind.holy_role

	if(!required_role)
		return TRUE

	return who.mind?.has_antag_datum(required_role)

/// A wrapper for role_check that applies side effects (stuns / damage) if the passed mob fails it.
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
	if(one_use)
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

// Muh side effects in Destroy()
// This stops the shade from being qdel'd immediately, and their ghost being sent back to the arrival shuttle.
/obj/item/soulstone/Destroy()
	if(captured_shade)
		INVOKE_ASYNC(captured_shade, /mob/living/proc/death)
		captured_shade = null
	return ..()

/obj/item/soulstone/attack_self(mob/living/user)
	. = ..()
	if(.)
		return TRUE
	if(!role_check_with_side_effects(user))
		return TRUE

	return release_shade(user)

/**
 * Releases the shade within our soulstone, if present.
 *
 * user - the mob who's releasing the shades (optional)
 * silent - should we send messages on release? Only matters if we pass a user
 */
/obj/item/soulstone/proc/release_shade(mob/user, silent = FALSE)
	if(!captured_shade)
		return FALSE

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
	return TRUE

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

/// Signal proc for [COMSIG_SOULSTONE_HIT]. Soulstones can be placed in construct shells to maek constructs.
/obj/structure/construct_shell/proc/on_soulstone_hit(datum/source, obj/item/soulstone/soulstone, mob/living/user)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, .proc/transfer_to_construct, soulstone, user)
	return SOULSTONE_HIT_HANDLED

/// Handles transferring a soulstone shade to this construct shell.
/obj/structure/construct_shell/proc/transfer_to_construct(obj/item/soulstone/soulstone, mob/living/user)
	if(!soulstone.captured_shade)
		to_chat(user, "[span_userdanger("Creation failed!")]: [soulstone] is empty! Go kill someone!")
		return FALSE

	var/construct_class = show_radial_menu(user, src, GLOB.construct_radial_images, custom_check = CALLBACK(src, .proc/check_menu, soulstone, user), require_near = TRUE, tooltips = TRUE)
	if(QDELETED(src) || QDELETED(soulstone.captured_shade) || !construct_class)
		return FALSE

	soulstone.captured_shade.mind?.remove_antag_datum(/datum/antagonist/cult)
	make_new_construct_from_class(construct_class, soulstone.theme, soulstone.captured_shade, user, FALSE, loc)
	qdel(soulstone)
	qdel(src)
	return TRUE

/// Callback for transfer_to_construct radial ui.
/obj/structure/construct_shell/proc/check_menu(obj/item/soulstone/soulstone, mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.is_holding(soulstone) || !user.CanReach(src, soulstone) || QDELETED(soulstone.captured_shade))
		return FALSE
	if(!soulstone.role_check(user))
		return FALSE
	return TRUE

/// Transfer the mind of a carbon mob (which is then dusted) into a shade mob inside src.
/// If forced, sacrifical and stat checks are skipped.
/obj/item/soulstone/proc/capture_soul(mob/living/carbon/victim, mob/user, forced = FALSE)
	if(!iscarbon(victim)) //TODO: Add sacrifice stoning for non-organics, just because you have no body doesnt mean you dont have a soul
		return FALSE
	if(captured_shade)
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
	var/mob/living/simple_animal/shade/soulstone_spirit = new(src)
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
	captured_shade = soulstone_spirit
	update_appearance()
	if(user)
		if(IS_CULTIST(user))
			to_chat(soulstone_spirit, span_bold("Your soul has been captured! \
				You are now bound to the cult's will. Help them succeed in their goals at all costs."))

		else if(role_check(user))
			to_chat(soulstone_spirit, span_bold("Your soul has been captured! You are now bound to [user.real_name]'s will. \
				Help [user.p_them()] succeed in [user.p_their()] goals at all costs."))
			assign_master(soulstone_spirit, user)

		if(message_user)
			to_chat(user, "[span_info("<b>Capture successful!</b>:")] [victim.real_name]'s soul has been ripped \
				from [victim.p_their()] body and stored within [src].")

	victim.dust(drop_items = TRUE)

/**
 * Assigns the bearer as the new master of a shade.
 */
/obj/item/soulstone/proc/assign_master(mob/shade, mob/user)
	if (!shade || !user || !shade.mind)
		return

	// Cult shades get cult datum
	if (user.mind.has_antag_datum(/datum/antagonist/cult))
		shade.mind.remove_antag_datum(/datum/antagonist/shade_minion)
		shade.mind.add_antag_datum(/datum/antagonist/cult)
		return

	// Only blessed soulstones can de-cult shades
	if(theme == THEME_HOLY)
		shade.mind.remove_antag_datum(/datum/antagonist/cult)

	var/datum/antagonist/shade_minion/shade_datum = shade.mind.has_antag_datum(/datum/antagonist/shade_minion)
	if (!shade_datum)
		shade_datum = shade.mind.add_antag_datum(/datum/antagonist/shade_minion)
	shade_datum.update_master(user.real_name)

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

	if(QDELETED(victim) || user.incapacitated() || !user.is_holding(src) || !user.CanReach(victim, src))
		return FALSE
	if(!chosen_ghost || !chosen_ghost.client)
		to_chat(user, span_danger("There were no spirits willing to become a shade."))
		return FALSE
	if(locate(/mob/living/simple_animal/shade) in src) //If they used the soulstone on someone else in the meantime
		return FALSE
	to_chat(user, "[span_info("<b>Capture successful!</b>:")] A spirit has entered [src], \
		taking upon the identity of [victim].")
	init_shade(victim, user, shade_controller = chosen_ghost)
	return TRUE

/**
 * Makes a construct based on a class and theme.
 *
 * construct_class - what class should the construct be? CONSTRUCT_JUGGERNAUT, CONSTRUCT_WRAITH, CONSTRUCT_ARTIFICER
 * target - who are we making into a construct?
 * creator - optional, who is creating our construct?
 * cultoverride - do we force the new mob to gain a cultist antag datum, regardless of whether we have a creator / or if the creator is a cultist?
 * loc_override - optional, moves the construct to the passed loc instead of just below the turf of the target
 */
/proc/make_new_construct_from_class(construct_class, theme = THEME_CULT, mob/target, mob/creator, cultoverride, loc_override)
	var/mob/living/simple_animal/hostile/construct/spawned_type
	switch(construct_class)
		if(CONSTRUCT_JUGGERNAUT)
			if(IS_CULTIST(creator) || cultoverride)
				spawned_type = /mob/living/simple_animal/hostile/construct/juggernaut

			else
				switch(theme)
					if(THEME_WIZARD)
						spawned_type = /mob/living/simple_animal/hostile/construct/juggernaut/mystic
					if(THEME_HOLY)
						spawned_type = /mob/living/simple_animal/hostile/construct/juggernaut/angelic
					if(THEME_CULT)
						spawned_type = /mob/living/simple_animal/hostile/construct/juggernaut/noncult

		if(CONSTRUCT_WRAITH)
			if(IS_CULTIST(creator) || cultoverride)
				spawned_type = /mob/living/simple_animal/hostile/construct/wraith

			else
				switch(theme)
					if(THEME_WIZARD)
						spawned_type = /mob/living/simple_animal/hostile/construct/wraith/mystic
					if(THEME_HOLY)
						spawned_type = /mob/living/simple_animal/hostile/construct/wraith/angelic
					if(THEME_CULT)
						spawned_type = /mob/living/simple_animal/hostile/construct/wraith/noncult

		if(CONSTRUCT_ARTIFICER)
			if(IS_CULTIST(creator) || cultoverride)
				spawned_type = /mob/living/simple_animal/hostile/construct/artificer

			else
				switch(theme)
					if(THEME_WIZARD)
						spawned_type = /mob/living/simple_animal/hostile/construct/artificer/mystic
					if(THEME_HOLY)
						spawned_type = /mob/living/simple_animal/hostile/construct/artificer/angelic
					if(THEME_CULT)
						spawned_type = /mob/living/simple_animal/hostile/construct/artificer/noncult

		else
			stack_trace("make_new_construct_from_class passed an invalid construct class.")
			return

	if(!ispath(spawned_type))
		stack_trace("make_new_construct_from_class didn't find a construct type to create.")
		return

	make_new_construct(spawned_type, target, creator, cultoverride, loc_override)

/**
 * Makes a construct for our mob.
 *
 * construct_type - typepath of what construct to instantiate and shove the target it.
 * target - the mob being constructed.
 * stoner - optional, who created our construct?
 * cultoverride - do we force the new mob to gain a cultist antag datum, regardless of whether we have a stoner / or if the stoner is a cultist?
 * loc_override - optional, moves the construct to the passed loc instead of just below the turf of the target
 */
/proc/make_new_construct(mob/living/simple_animal/hostile/construct/construct_type, mob/target, mob/stoner, cultoverride = FALSE, loc_override)
	if(QDELETED(target))
		CRASH("make_new_construct passed a qdeleted target.")

	var/mob/living/simple_animal/hostile/construct/new_construct = new construct_type(loc_override || get_turf(target))
	flick("make_[new_construct.icon_state][new_construct.theme]", new_construct)

	playsound(new_construct, 'sound/effects/constructform.ogg', 50)
	if(stoner)
		new_construct.faction |= "[REF(stoner)]"
		new_construct.master = stoner
		var/datum/action/innate/seek_master/find_master = new(new_construct)
		find_master.Grant(new_construct)

	if(target.mind)
		target.mind.transfer_to(new_construct)
	else
		new_construct.key = target.key

	var/atom/movable/screen/alert/bloodsense/blood_sense

	if(new_construct.mind && (IS_CULTIST(stoner) || cultoverride))
		new_construct.mind.add_antag_datum(/datum/antagonist/cult)

	var/who_to_follow = stoner?.p_their() || "their"
	if(IS_CULTIST(stoner) || cultoverride)
		to_chat(new_construct, span_bold("You are still bound to serve the cult[stoner ? " and [stoner]":""], follow [who_to_follow] orders and help [who_to_follow] complete [who_to_follow] goals at all costs."))

	else if(stoner)
		to_chat(new_construct, span_bold("You are still bound to serve your creator, [stoner], follow [who_to_follow] orders and help [who_to_follow] complete [who_to_follow] goals at all costs."))

	new_construct.clear_alert("bloodsense")
	blood_sense = new_construct.throw_alert("bloodsense", /atom/movable/screen/alert/bloodsense)
	if(blood_sense)
		blood_sense.Cviewer = new_construct
	new_construct.cancel_camera()

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
	if(!GLOB.deity)
		return

	name = "[GLOB.deity]'s punishment"
	desc = "A prison for those who lost [GLOB.deity]'s game."

/obj/item/soulstone/anybody/mining
	grab_sleeping = FALSE
