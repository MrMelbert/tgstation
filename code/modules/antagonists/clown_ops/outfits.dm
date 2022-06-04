/datum/outfit/syndicate/clownop
	name = "Clown Operative - Basic"

	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	mask = /obj/item/clothing/mask/gas/clown_hat
	back = /obj/item/storage/backpack/clown
	l_pocket = /obj/item/pinpointer/nuke/syndicate
	r_pocket = /obj/item/bikehorn
	implants = list(/obj/item/implant/sad_trombone)
	id_trim = /datum/id_trim/chameleon/operative/clown

	uplink_type = /obj/item/uplink/clownop

/datum/outfit/syndicate/clownop/New()
	// Add some clown specific funnies to their backpack
	backpack_contents += list(
		// Clumsy mutator, if you wanna be a true clown for the memes
		/obj/item/dnainjector/clumsymut,
		// For any guns that you get your grubby little clown op mitts on
		/obj/item/storage/box/syndie_kit/clownpins,
		/obj/item/reagent_containers/spray/waterflower/lube,
		/obj/item/mod/skin_applier/honkerative,
	)
	return ..()

/datum/outfit/syndicate/clownop/plasmaman
	name = "Clown Operative - Basic Plasmaman"

	uniform = /obj/item/clothing/under/plasmaman/clown
	head = /obj/item/clothing/head/helmet/space/plasmaman/clown
	mask = /obj/item/clothing/mask/gas/clown_hat/plasmaman
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/clownop/no_crystals
	name = "Clown Operative - Reinforcement / No TC"
	tc = 0

/datum/outfit/syndicate/clownop/no_crystals/plasmaman
	name = "Clown Operative - Reinforcement Plasmaman / No TC"

	uniform = /obj/item/clothing/under/plasmaman/clown
	head = /obj/item/clothing/head/helmet/space/plasmaman/clown
	mask = /obj/item/clothing/mask/gas/clown_hat/plasmaman
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/syndicate/clownop/leader
	name = "Clown Operative Leader - Basic"
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	id_trim = /datum/id_trim/chameleon/operative/clown_leader
	command_radio = TRUE

/datum/outfit/syndicate/clownop/leader/plasmaman
	name = "Clown Operative Leader - Basic Plasmaman"

	uniform = /obj/item/clothing/under/plasmaman/clown
	head = /obj/item/clothing/head/helmet/space/plasmaman/clown
	mask = /obj/item/clothing/mask/gas/clown_hat/plasmaman
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/clown_operative
	name = "Clown Operative (Preview only)"

	back = /obj/item/mod/control/pre_equipped/empty/syndicate/honkerative
	uniform = /obj/item/clothing/under/syndicate

/datum/outfit/clown_operative/post_equip(mob/living/carbon/human/H, visualsOnly)
	var/obj/item/mod/module/armor_booster/booster = locate() in H.back
	booster.active = TRUE
	H.update_inv_back()

/datum/outfit/clown_operative_elite
	name = "Clown Operative (Elite, Preview only)"

	back = /obj/item/mod/control/pre_equipped/empty/syndicate/honkerative
	uniform = /obj/item/clothing/under/syndicate

/datum/outfit/clown_operative_elite/post_equip(mob/living/carbon/human/H, visualsOnly)
	var/obj/item/mod/module/armor_booster/booster = locate() in H.back
	booster.active = TRUE
	H.update_inv_back()
