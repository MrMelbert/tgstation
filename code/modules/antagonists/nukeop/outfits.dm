/datum/outfit/syndicate
	name = "Syndicate Operative - Basic"

	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack/fireproof
	ears = /obj/item/radio/headset/syndicate/alt
	l_pocket = /obj/item/modular_computer/tablet/nukeops
	id = /obj/item/card/id/advanced/chameleon
	belt = /obj/item/gun/ballistic/automatic/pistol
	backpack_contents = list(
		/obj/item/storage/box/survival/syndie = 1,
		/obj/item/knife/combat/survival,
	)

	skillchips = list(/obj/item/skillchip/disk_verifier)
	id_trim = /datum/id_trim/chameleon/operative

	/// How much TC does our uplinks tart with?
	var/tc = 25
	/// if TRUE, give the headset we equip our op with command / bigvoice
	var/command_radio = FALSE
	/// The type of uplink we get on equip
	var/uplink_type = /obj/item/uplink/nuclear

/datum/outfit/syndicate/post_equip(mob/living/carbon/human/equipped_to)
	var/obj/item/radio/syndie_radio = equipped_to.ears
	if(syndie_radio)
		syndie_radio.set_frequency(FREQ_SYNDICATE)
		syndie_radio.freqlock = TRUE
		if(command_radio)
			syndie_radio.command = TRUE

	if(ispath(uplink_type, /obj/item/uplink/nuclear) || tc) // /obj/item/uplink/nuclear understands 0 tc
		var/obj/item/new_uplink = new uplink_type(equipped_to, equipped_to.key, tc)
		equipped_to.equip_to_slot_or_del(new_uplink, ITEM_SLOT_BACKPACK)

	var/obj/item/implant/weapons_auth/auth_implant = new /obj/item/implant/weapons_auth(equipped_to)
	auth_implant.implant(equipped_to)
	var/obj/item/implant/explosive/microbomb_implant = new /obj/item/implant/explosive(equipped_to)
	microbomb_implant.implant(equipped_to)

	equipped_to.faction |= ROLE_SYNDICATE
	equipped_to.update_icons()

/datum/outfit/syndicate/plasmaman
	name = "Syndicate Operative - Basic Plasmaman"
	head = /obj/item/clothing/head/helmet/space/plasmaman/syndie
	mask = /obj/item/clothing/mask/gas/syndicate
	uniform = /obj/item/clothing/under/plasmaman/syndicate
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/leader
	name = "Syndicate Leader - Basic"
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	id_trim = /datum/id_trim/chameleon/operative/nuke_leader
	command_radio = TRUE

/datum/outfit/syndicate/leader/plasmaman
	name = "Syndicate Leader - Basic Plasmaman"
	head = /obj/item/clothing/head/helmet/space/plasmaman/syndie
	mask = /obj/item/clothing/mask/gas/syndicate
	uniform = /obj/item/clothing/under/plasmaman/syndicate
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/no_crystals
	name = "Syndicate Operative - Reinforcement / No TC"
	tc = 0

/datum/outfit/syndicate/no_crystals/plasmaman
	name = "Syndicate Operative - Reinforcement Plasmaman / No TC"
	head = /obj/item/clothing/head/helmet/space/plasmaman/syndie
	mask = /obj/item/clothing/mask/gas/syndicate
	uniform = /obj/item/clothing/under/plasmaman/syndicate
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/full
	name = "Syndicate Operative - Full Kit / Lone Op"

	glasses = /obj/item/clothing/glasses/night
	mask = /obj/item/clothing/mask/gas/syndicate
	back = /obj/item/mod/control/pre_equipped/nuclear
	r_pocket = /obj/item/tank/internals/emergency_oxygen/engi
	internals_slot = ITEM_SLOT_RPOCKET
	belt = /obj/item/storage/belt/military
	r_hand = /obj/item/gun/ballistic/shotgun/bulldog
	backpack_contents = list(
		/obj/item/storage/box/survival/syndie = 1,
		/obj/item/gun/ballistic/automatic/pistol = 1,
		/obj/item/knife/combat/survival,
	)

/datum/outfit/syndicate/full/plasmaman
	name = "Syndicate Operative -  Full Kit / Lone Op Plasmaman"
	back = /obj/item/mod/control/pre_equipped/nuclear/plasmaman
	uniform = /obj/item/clothing/under/plasmaman/syndicate
	r_pocket = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/full/plasmaman/New()
	backpack_contents += /obj/item/clothing/head/helmet/space/plasmaman/syndie
	return ..()

/datum/outfit/nuclear_operative
	name = "Nuclear Operative (Preview only)"

	back = /obj/item/mod/control/pre_equipped/empty/syndicate
	uniform = /obj/item/clothing/under/syndicate

/datum/outfit/nuclear_operative/post_equip(mob/living/carbon/human/H, visualsOnly)
	var/obj/item/mod/module/armor_booster/booster = locate() in H.back
	booster.active = TRUE
	H.update_inv_back()

/datum/outfit/nuclear_operative_elite
	name = "Nuclear Operative (Elite, Preview only)"

	back = /obj/item/mod/control/pre_equipped/empty/elite
	uniform = /obj/item/clothing/under/syndicate
	l_hand = /obj/item/modular_computer/tablet/nukeops
	r_hand = /obj/item/shield/energy

/datum/outfit/nuclear_operative_elite/post_equip(mob/living/carbon/human/H, visualsOnly)
	var/obj/item/mod/module/armor_booster/booster = locate() in H.back
	booster.active = TRUE
	H.update_inv_back()
	var/obj/item/shield/energy/shield = locate() in H.held_items
	shield.icon_state = "[shield.base_icon_state]1"
	H.update_inv_hands()
