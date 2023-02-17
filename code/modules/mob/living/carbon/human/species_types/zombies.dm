/datum/species/zombie
	// 1spooky
	name = "High-Functioning Zombie"
	id = SPECIES_ZOMBIE
	sexes = 0
	meat = /obj/item/food/meat/slab/human/mutant/zombie
	mutanttongue = /obj/item/organ/internal/tongue/zombie
	species_traits = list(
		NOZOMBIE,
		NOTRANSSTING,
	)
	inherent_traits = list(
		TRAIT_EASILY_WOUNDED,
		TRAIT_EASYDISMEMBER,
		TRAIT_FAKEDEATH,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NOBLOOD,
		TRAIT_NOBREATH,
		TRAIT_NOCLONELOSS,
		TRAIT_NODEATH,
		TRAIT_NOHUNGER,
		TRAIT_NOMETABOLISM,
		TRAIT_NO_BODY_TEMPERATURE_REGULATION,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_SUCCUMB_OVERRIDE,
		TRAIT_TOXIMMUNE,
	)
	mutantstomach = null
	mutantheart = null
	mutantliver = null
	mutantlungs = null
	inherent_biotypes = MOB_UNDEAD|MOB_HUMANOID
	disliked_food = NONE
	liked_food = ZOMBIE_FAVORITES
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | ERT_SPAWN
	bodytemp_normal = T0C // They have no natural body heat, the environment regulates body temp
	bodytemp_heat_damage_limit = FIRE_MINIMUM_TEMPERATURE_TO_EXIST // Take damage at fire temp
	bodytemp_cold_damage_limit = MINIMUM_TEMPERATURE_TO_MOVE // take damage below minimum movement temp

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/zombie,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/zombie,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/zombie,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/zombie,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/zombie,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/zombie
	)

/datum/species/zombie/check_roundstart_eligible()
	if(check_holidays(HALLOWEEN))
		return TRUE
	return ..()

/datum/species/zombie/get_species_description()
	return "A rotting zombie! They descend upon Space Station Thirteen Every year to spook the crew! \"Sincerely, the Zombies!\""

/datum/species/zombie/get_species_lore()
	return list("Zombies have long lasting beef with Botanists. Their last incident involving a lawn with defensive plants has left them very unhinged.")

// Override for the default temperature perks, so we can establish that they don't care about temperature very much
/datum/species/zombie/create_pref_temperature_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "thermometer-half",
		SPECIES_PERK_NAME = "No Body Temperature",
		SPECIES_PERK_DESC = "Having long since departed, Zombies do not have anything \
			regulating their body temperature anymore. This means that \
			the environment decides their body temperature - which they don't mind at \
			all, until it gets a bit too hot.",
	))

	return to_add
