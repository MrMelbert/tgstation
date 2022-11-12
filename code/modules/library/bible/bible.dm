/obj/item/book/bible
	name = "bible"
	desc = "Apply to head repeatedly."
	icon = 'icons/obj/bibles.dmi'
	icon_state = "bible"
	inhand_icon_state = "bible"
	worn_icon_state = "bible"
	lefthand_file = 'icons/mob/inhands/items/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/books_righthand.dmi'
	force_string = "holy"
	unique = TRUE
	starting_author = "Unknown"
	var/deity_name = "Christ"

/obj/item/book/bible/examine(mob/user)
	. = ..()
	if(!user.mind?.holy_role)
		return
	if(length(GLOB.chaplain_altars))
		. += span_notice("[src] has an expansion pack to replace any broken Altar.")
	else
		. += span_notice("[src] can be unpacked by hitting the floor of a holy area with it.")

/obj/item/book/bible/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/anti_magic, MAGIC_RESISTANCE_HOLY)
	RegisterSignal(src, COMSIG_BIBLE_SMACKED, .proc/on_bible_smack)
	hollow_out_book()

/obj/item/book/bible/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is offering [user.p_them()]self to [deity_name]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (BRUTELOSS)

/obj/item/book/bible/proc/on_bible_smack(obj/item/book/bible/source, mob/user, obj/item/book/bible/hit_us)
	SIGNAL_HANDLER

	// Apply our global bible skin if we have it
	if(GLOB.current_bible_skin)
		if(icon_state == GLOB.current_bible_skin.bible_icon_state)
			return

		GLOB.current_bible_skin.apply_reskin(user, src)

	// Otherwise just copy the name, icon_state, etc
	else
		if(icon_state == hit_us.icon_state)
			return

		name = hit_us.name
		desc = hit_us.desc
		deity_name = hit_us.deity_name
		icon = hit_us.icon
		icon_state = hit_us.icon_state
		lefthand_file = hit_us.lefthand_file
		righthand_file = hit_us.righthand_file
		inhand_icon_state = hit_us.inhand_icon_state

	balloon_alert(user, "converted")
	playsound(src, 'sound/effects/magic.ogg', 50, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE, frequency = 2)
	do_smoke(range = 0, holder = src, location = drop_location(), smoke_type = /obj/effect/particle_effect/fluid/smoke/quick)
	return COMSIG_END_BIBLE_CHAIN

/obj/item/book/bible/attack_self(mob/living/carbon/human/user)
	if(user.mind?.holy_role != HOLY_ROLE_HIGHPRIEST)
		return ..()
	if(GLOB.current_bible_skin)
		return FALSE

	var/static/list/skins_to_images
	if(!skins_to_images)
		skins_to_images = list()
		for(var/skin_name in GLOB.bible_names_to_skins)
			var/datum/bible_skin/skin = GLOB.bible_names_to_skins[skin_name]
			skins_to_images[skin_name] = image(icon = skin.bible_icon, icon_state = skin.bible_icon_state)

	var/choice = show_radial_menu(user, src, skins_to_images, custom_check = CALLBACK(src, .proc/check_menu, user), radius = 40, require_near = TRUE)
	if(!choice)
		return FALSE

	var/datum/bible_skin/picked_skin = GLOB.bible_names_to_skins[choice]
	if(!istype(picked_skin))
		return FALSE

	picked_skin.apply_reskin(user, src)
	GLOB.current_bible_skin = picked_skin
	SSblackbox.record_feedback("text", "religion_book", 1, "[choice]")
	return TRUE

/**
 * Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The mob interacting with the menu
 */
/obj/item/book/bible/proc/check_menu(mob/living/carbon/human/user)
	if(GLOB.current_bible_skin)
		return FALSE
	if(!istype(user) || !user.is_holding(src))
		return FALSE
	if(user.incapacitated() || user.mind?.holy_role != HOLY_ROLE_HIGHPRIEST)
		return FALSE
	return TRUE

/obj/item/book/bible/proc/make_new_altar(atom/bible_smacked, mob/user)
	var/new_altar_area = get_turf(bible_smacked)

	balloon_alert(user, "unpacking bible...")
	if(!do_after(user, 15 SECONDS, new_altar_area))
		balloon_alert(user, "interrupted!")
		return
	var/obj/structure/altar_of_gods/altar = new(new_altar_area)
	altar.balloon_alert(user, "altar created")
	qdel(src)

/obj/item/book/bible/proc/bless(mob/living/L, mob/living/user)
	if(GLOB.religious_sect)
		return GLOB.religious_sect.sect_bless(L,user)
	if(!ishuman(L))
		return
	var/mob/living/carbon/human/H = L
	for(var/obj/item/bodypart/bodypart as anything in H.bodyparts)
		if(!IS_ORGANIC_LIMB(bodypart))
			balloon_alert(user, "can't heal metal!")
			return 0

	var/heal_amt = 10
	var/list/hurt_limbs = H.get_damaged_bodyparts(1, 1, null, BODYTYPE_ORGANIC)

	if(hurt_limbs.len)
		for(var/X in hurt_limbs)
			var/obj/item/bodypart/affecting = X
			if(affecting.heal_damage(heal_amt, heal_amt, null, BODYTYPE_ORGANIC))
				H.update_damage_overlays()
		H.visible_message(span_notice("[user] heals [H] with the power of [deity_name]!"))
		to_chat(H, span_boldnotice("May the power of [deity_name] compel you to be healed!"))
		playsound(src.loc, SFX_PUNCH, 25, TRUE, -1)
		H.add_mood_event("blessing", /datum/mood_event/blessing)
	return TRUE

/obj/item/book/bible/attack(mob/living/hit_mob, mob/living/carbon/human/user, params, heal_mode = TRUE)
	if (!ISADVANCEDTOOLUSER(user))
		balloon_alert(user, "not dextrous enough!")
		return

	if (HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50))
		to_chat(user, span_danger("[src] slips out of your hand and hits your head."))
		user.take_bodypart_damage(10)
		user.Unconscious(40 SECONDS)
		return

	if (!user.mind?.holy_role)
		to_chat(user, span_danger("The book sizzles in your hands."))
		user.take_bodypart_damage(burn = 10)
		return

	if (!heal_mode)
		return ..()

	if (hit_mob.stat == DEAD)
		hit_mob.visible_message(span_danger("[user] smacks [hit_mob]'s lifeless corpse with [src]."))
		playsound(loc, SFX_PUNCH, 25, TRUE, -1)
		return

	if(user == hit_mob)
		balloon_alert(user, "can't heal yourself!")
		return

	var/smack = TRUE
	var/brain_damage = FALSE

	if(prob(60) && bless(hit_mob, user))
		smack = FALSE

	else if(iscarbon(hit_mob))
		var/mob/living/carbon/carbon_hit = hit_mob
		if(!istype(carbon_hit.head, /obj/item/clothing/head/helmet))
			carbon_hit.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5, 60)
			carbon_hit.balloon_alert(carbon_hit, "you feel dumber")
			brain_damage = TRUE

	if(!smack)
		return

	hit_mob.visible_message(
		span_danger("[user] beats [hit_mob] over the head with [src]!"),
		"<span class=[brain_damage ? "userdanger":"danger"]>[user] beats [hit_mob] over the head with [src]!</span>",
	)
	playsound(loc, SFX_PUNCH, 25, TRUE, -1)
	if(brain_damage)
		log_combat(user, hit_mob, "hit with bible", src, addition = "(causing brain damage)")
	else
		log_combat(user, hit_mob, "hit with bible", src)

/obj/item/book/bible/afterattack(atom/bible_smacked, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!user.mind || !user.mind.holy_role)
		return

	if(SEND_SIGNAL(bible_smacked, COMSIG_BIBLE_SMACKED, user, src) & COMSIG_END_BIBLE_CHAIN)
		return

	if(isfloorturf(bible_smacked))
		var/area/current_area = get_area(bible_smacked)
		if(!length(GLOB.chaplain_altars) && istype(current_area, /area/station/service/chapel))
			make_new_altar(bible_smacked, user)
			return

		var/revealed_runes = FALSE
		for(var/obj/effect/rune/nearby_runes in orange(2, user))
			nearby_runes.invisibility = 0
			revealed_runes = TRUE
			if(!revealed_runes)
				revealed_runes = TRUE
				bible_smacked.balloon_alert(user, "runes revealed!") // "!" is normally reserved for failure, but this is an "oh shit" moment

// The bible is too boring to read.
// Future idea: Allow chaplains to fill their bibles with text!
/obj/item/book/bible/on_read(mob/reader)
	return

/obj/item/book/bible/booze
	desc = "To be applied to the head repeatedly."

/obj/item/book/bible/booze/Initialize(mapload)
	. = ..()
	new /obj/item/reagent_containers/cup/glass/bottle/whiskey(src)

/obj/item/book/bible/syndicate
	name = "Syndicate Tome"
	icon_state ="ebook"
	throw_speed = 2
	throwforce = 18
	throw_range = 7
	force = 18
	hitsound = 'sound/weapons/sear.ogg'
	damtype = BURN
	attack_verb_continuous = list("attacks", "burns", "blesses", "damns", "scorches")
	attack_verb_simple = list("attack", "burn", "bless", "damn", "scorch")
	deity_name = "The Syndicate"
	/// How many people can link to our bible?
	var/uses = 1

/obj/item/book/bible/syndicate/on_bible_smack(obj/item/book/bible/source, mob/user, obj/item/book/bible/hit_us)
	return

/obj/item/book/bible/syndicate/attack_self(mob/living/carbon/human/user)
	if(!uses)
		return FALSE

	user.mind.holy_role = HOLY_ROLE_PRIEST
	uses -= 1
	to_chat(user, span_userdanger("You try to open the book AND IT BITES YOU!"))
	playsound(loc, 'sound/effects/snap.ogg', 50, TRUE)
	user.apply_damage(5, BRUTE, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
	to_chat(user, span_notice("Your name appears on the inside cover, in blood."))
	desc += span_warning("The name [user.real_name] is written in blood inside the cover.")

/obj/item/book/bible/syndicate/attack(mob/living/hit_mob, mob/living/carbon/human/user, params, heal_mode = TRUE)
	// Combat mode = TRUE, then pass down heal = FALSE
	// Likewise, combat mode = FALSE< then pass down heal = TRUE
	return ..(hit_mob, user, heal_mode = !user.combat_mode)

/obj/item/book/bible/syndicate/add_blood_DNA(list/blood_dna)
	return FALSE
