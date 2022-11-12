/proc/generate_bible_skins_by_images()
	RETURN_TYPE(/list)

	var/list/skins = list()
	for(var/skin_type in typesof(/datum/bible_skin))
		var/datum/bible_skin/skin_singleton = new skin_type()
		skins[skin_singleton] = image(icon = skin_singleton.bible_icon, icon_state = skin_singleton.bible_icon_state)
		GLOB.bible_skins_to_names[skin_singleton.name] = skin_singleton

	return skins

/proc/generate_bible_skins_by_name()
	RETURN_TYPE(/list)

	var/list/skins = list()
	for(var/datum/bible_skin/skin as anything in GLOB.bible_skins_to_images)
		skins[skin.name] = skin

	return skins

/datum/bible_skin
	var/name = "Bible"
	var/deity_name = "God"
	var/bible_icon = 'icons/obj/bibles.dmi'
	var/bible_icon_state = "bible"
	var/bible_lefthand_icon = 'icons/mob/inhands/misc/bibles_lefthand.dmi'
	var/bible_righthand_icon = 'icons/mob/inhands/misc/bibles_righthand.dmi'
	var/bible_inhand_icon_state = "bible"

/datum/bible_skin/proc/apply_reskin(mob/living/carbon/human/reskinner, obj/item/book/bible/reskinned)

	if(GLOB.bible_name)
		reskinned.name = GLOB.bible_name

	else if(name)
		reskinned.name = name

	if(GLOB.deity)
		reskinned.deity_name = GLOB.deity
	else if(deity_name)
		reskinned.deity_name = deity_name

	if(bible_icon)
		reskinned.icon = bible_icon

	if(bible_icon_state)
		reskinned.icon_state = bible_icon_state

	if(bible_lefthand_icon)
		reskinned.lefthand_file = bible_lefthand_icon

	if(bible_righthand_icon)
		reskinned.righthand_file = bible_righthand_icon

	if(bible_inhand_icon_state)
		reskinned.inhand_icon_state = bible_inhand_icon_state

/datum/bible_skin/quran
	name = "Quran"
	bible_icon_state = "koran"
	bible_inhand_icon_state = "koran"

/datum/bible_skin/quran
	name = "Scrapbook"
	deity_name = null
	bible_icon_state = "scrapbook"
	bible_inhand_icon_state = "scrapbook"

/datum/bible_skin/fire
	name = "Burning Bible"
	deity_name = null
	bible_icon_state = "burning"
	bible_inhand_icon_state = "burning"

/datum/bible_skin/clown
	name = "Clown Bible"
	deity_name = "Honkmother"
	bible_icon_state = "honk1"
	bible_inhand_icon_state = "honk1"

/datum/bible_skin/clown/apply_reskin(mob/living/carbon/human/reskinner, obj/item/book/bible/reskinned)
	. = ..()
	if(!istype(reskinner))
		return
	reskinner.dna?.add_mutation(/datum/mutation/human/clumsy)
	reskinner.equip_to_slot_or_del(new /obj/item/clothing/mask/gas/clown_hat(reskinner), ITEM_SLOT_MASK)

/datum/bible_skin/clown/alt
	name = "Banana Bible"
	bible_icon_state = "honk2"
	bible_inhand_icon_state = "honk2"

/datum/bible_skin/minecraft // I just thought it'd be cursed if we had a /minecraft typepath somewhere
	name = "Creeper Bible"
	deity_name = "Steve"
	bible_icon_state = "creeper"
	bible_inhand_icon_state = "creeper"

/datum/bible_skin/white
	name = "White Bible"
	bible_icon_state = "white"
	bible_inhand_icon_state = "white"

/datum/bible_skin/holy
	name = "Holy Light"
	bible_icon_state = "holylight"
	bible_inhand_icon_state = "holylight"

/datum/bible_skin/atheist
	name = "The God Delusion"
	deity_name = null
	bible_icon_state = "atheist"
	bible_inhand_icon_state = "atheist"

/datum/bible_skin/atheist
	name = "Tome"
	bible_icon_state = "tome"
	bible_inhand_icon_state = "tome"

/datum/bible_skin/king
	name = "The King in Yellow"
	bible_icon_state = "kingyellow"
	bible_inhand_icon_state = "kingyellow"

/datum/bible_skin/ithaqua
	name = "Ithaqua"
	bible_icon_state = "ithaqua"
	bible_inhand_icon_state = "ithaqua"

/datum/bible_skin/scientology
	name = "Scientology"
	deity_name = "Science"
	bible_icon_state = "scientology"
	bible_inhand_icon_state = "scientology"

/datum/bible_skin/melted
	name = "Melted Bible"
	deity_name = null
	bible_icon_state = "melted"
	bible_inhand_icon_state = "melted"

/datum/bible_skin/necronomicon
	name = "Necronomicon"
	deity_name = null
	bible_icon_state = "necronomicon"
	bible_inhand_icon_state = "necronomicon"

/datum/bible_skin/insuls
	name = "Insulationism"
	deity_name = null
	bible_icon_state = "insuls"
	bible_inhand_icon_state = "kingyellow"

/datum/bible_skin/insuls/apply_reskin(mob/living/carbon/human/reskinner, obj/item/book/bible/reskinned)
	. = ..()
	if(!istype(reskinner))
		return
	var/obj/item/clothing/gloves/color/fyellow/insuls = new(get_turf(reskinner))
	insuls.name = "insuls"
	insuls.desc = "A mere copy of the true insuls."
	insuls.siemens_coefficient = 0.99999
	reskinner.equip_to_slot(insuls, ITEM_SLOT_GLOVES)

/datum/bible_skin/guru
	name = "Guru Granth Sahib"
	bible_icon_state = "gurugranthsahib"
	bible_inhand_icon_state = "gurugranthsahib"

/datum/bible_skin/japanese
	name = "Koijiki"
	bible_icon_state = "koijiki"
	bible_inhand_icon_state = "koijiki"
