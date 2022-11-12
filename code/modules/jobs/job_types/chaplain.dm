/datum/job/chaplain
	title = JOB_CHAPLAIN
	description = "Hold services and funerals, cremate people, preach your \
		religion, protect the crew against cults."
	department_head = list(JOB_HEAD_OF_PERSONNEL)
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = SUPERVISOR_HOP
	selection_color = "#bbe291"
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "CHAPLAIN"

	outfit = /datum/outfit/job/chaplain
	plasmaman_outfit = /datum/outfit/plasmaman/chaplain

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_SRV

	display_order = JOB_DISPLAY_ORDER_CHAPLAIN
	departments_list = list(
		/datum/job_department/service,
		)

	family_heirlooms = list(/obj/item/toy/windup_toolbox, /obj/item/reagent_containers/cup/glass/bottle/holywater)

	mail_goodies = list(
		/obj/item/reagent_containers/cup/glass/bottle/holywater = 30,
		/obj/item/toy/plush/awakenedplushie = 10,
		/obj/item/grenade/chem_grenade/holy = 5,
		/obj/item/toy/plush/narplush = 2,
		/obj/item/toy/plush/ratplush = 1
	)
	rpg_title = "Paladin"
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_REOPEN_ON_ROUNDSTART_LOSS | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN | JOB_CAN_BE_INTERN

	voice_of_god_power = 2 //Chaplains are very good at speaking with the voice of god


/datum/job/chaplain/after_spawn(mob/living/spawned, client/player_client)
	. = ..()
	if(!ishuman(spawned))
		return
	var/mob/living/carbon/human/our_father = spawned
	var/obj/item/book/bible/booze/holy_book = new(our_father.loc)

	// There's an existing religion on station
	if(GLOB.religion)
		if(our_father.mind)
			our_father.mind.holy_role = HOLY_ROLE_PRIEST

		if(GLOB.current_bible_skin)
			GLOB.current_bible_skin.apply_reskin(our_father, holy_book)

		else
			if(GLOB.bible_name)
				holy_book.name = GLOB.bible_name
			if(GLOB.deity)
				holy_book.deity_name = GLOB.deity

		to_chat(our_father, span_boldnotice("There is already an established religion onboard the station. You are an acolyte of [GLOB.deity]. Defer to the Chaplain."))
		our_father.equip_to_slot_or_del(holy_book, ITEM_SLOT_BACKPACK)
		var/religious_tool_typepath = GLOB.holy_weapon_type || /obj/item/nullrod
		var/obj/item/nullrod/new_holyweapon = new religious_tool_typepath(our_father.loc)
		our_father.put_in_hands(new_holyweapon)
		if(GLOB.religious_sect)
			GLOB.religious_sect.on_conversion(our_father)
		return

	if(our_father.mind)
		our_father.mind.holy_role = HOLY_ROLE_HIGHPRIEST

	var/bible_skin = player_client?.prefs?.read_preference(/datum/preference/choiced/bible_skin) || DEFAULT_BIBLE_SKIN
	var/datum/bible_skin/skin_to_use = GLOB.bible_skins_to_names[bible_skin]
	if(skin_to_use)
		skin_to_use.apply_reskin(our_father, holy_book)
		GLOB.current_bible_skin = skin_to_use

	var/new_religion = player_client?.prefs?.read_preference(/datum/preference/name/religion) || DEFAULT_RELIGION
	var/new_deity = player_client?.prefs?.read_preference(/datum/preference/name/deity) || DEFAULT_DEITY
	var/new_bible = player_client?.prefs?.read_preference(/datum/preference/name/bible) || DEFAULT_BIBLE

	switch(lowertext(new_religion))
		if("homosexuality", "gay", "penis", "ass", "cock", "cocks")
			new_bible = pick("Guys Gone Wild", "Coming Out of The Closet", "War of Cocks")
			if(new_bible == "War of Cocks")
				new_deity = pick("Dick Powers", "King Cock")
			else
				new_deity = pick("Gay Space Jesus", "Gandalf", "Dumbledore")

			our_father.adjustOrganLoss(ORGAN_SLOT_BRAIN, 100) // starts off brain damaged as fuck

		if("lol", "wtf", "poo", "badmin", "shitmin", "deadmin", "meme", "memes")
			switch(rand(1, 3))
				if(1)
					new_bible = "Woody's Got Wood: The Aftermath"
					new_deity = pick("Woody", "Andy", "Cherry Flavored Lube")
				if(2)
					new_bible = "Sweet Bro and Hella Jeff: Expanded Edition"
					new_deity = pick("Sweet Bro", "Hella Jeff", "Stairs", "AH")
				if(3)
					new_bible = "F.A.T.A.L. Rulebook"
					new_deity = "Twenty Ten-Sided Dice"

			our_father.adjustOrganLoss(ORGAN_SLOT_BRAIN, 100) // also starts off brain damaged as fuck

		if("servicianism", "partying")
			holy_book.desc = "Happy, Full, Clean. Live it and give it."

		if("weeaboo", "kawaii")
			new_bible = pick("Fanfiction Compendium", "Japanese for Dummies", "The Manganomicon", "Establishing Your O.T.P")
			new_deity = "Anime"

		else
			if(new_bible == DEFAULT_BIBLE)
				new_bible = DEFAULT_BIBLE_REPLACE(new_religion)

	holy_book.name = new_bible
	holy_book.deity_name = new_deity

	GLOB.religion = new_religion
	GLOB.bible_name = new_bible
	GLOB.deity = new_deity

	our_father.equip_to_slot_or_del(holy_book, ITEM_SLOT_BACKPACK)

	if(skin_to_use)
		SSblackbox.record_feedback("text", "religion_book", 1, "[bible_skin]", 1)

	SSblackbox.record_feedback("text", "religion_name", 1, "[new_religion]", 1)
	SSblackbox.record_feedback("text", "religion_deity", 1, "[new_deity]", 1)
	SSblackbox.record_feedback("text", "religion_bible", 1, "[new_bible]", 1)

/datum/outfit/job/chaplain
	name = "Chaplain"
	jobtype = /datum/job/chaplain

	id_trim = /datum/id_trim/job/chaplain
	uniform = /obj/item/clothing/under/rank/civilian/chaplain
	backpack_contents = list(
		/obj/item/camera/spooky = 1,
		/obj/item/stamp/chap = 1,
		)
	belt = /obj/item/modular_computer/tablet/pda/chaplain
	ears = /obj/item/radio/headset/headset_srv

	backpack = /obj/item/storage/backpack/cultpack
	satchel = /obj/item/storage/backpack/cultpack

	chameleon_extras = /obj/item/stamp/chap
	skillchips = list(/obj/item/skillchip/entrails_reader)
