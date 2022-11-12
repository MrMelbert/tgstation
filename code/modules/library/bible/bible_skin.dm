/**
 * Generates a list of [bible names] to [bible skin singletons]
 */
/proc/generate_bible_skins_by_name()
	RETURN_TYPE(/list)

	var/list/skins = list()
	for(var/skin_type in typesof(/datum/bible_skin))
		var/datum/bible_skin/skin_singleton = new skin_type()
		if(isnull(skin_singleton.name))
			stack_trace("Hey! Why is there a bible skin with no name? Set up your skin correctly! ([skin_type])")
			qdel(skin_singleton)
			continue
		else if(skin_singleton.name in skins)
			var/datum/bible_skin/existing_singleton = skins[skin_singleton.name]
			stack_trace("Hey! [skin_type] has a duplicate bible name with [existing_singleton.type]! Please amend this!")
			qdel(skin_singleton)
			continue

		skins[skin_singleton.name] = skin_singleton

	return skins

/**
 * # Bible skin
 *
 * These singletons reskin the bible! Yes, that's it.
 *
 * Also lets you apply side effects when the skin is selected.
 */
/datum/bible_skin
	/// The name the bible becomes when this skin is selected, if a global bible name is not set.
	/// This is also used for keying the global list, for use in the prefs menu.
	var/name = "Bible"
	/// The deity name that comes with the skin, if a global deity name is not set.
	var/deity_name = "God"
	/// The icon file to use for the bible
	var/bible_icon = 'icons/obj/bibles.dmi'
	/// The icon state to use for the bible
	var/bible_icon_state = "bible"
	/// The lefthand icon file to use for the bible
	var/bible_lefthand_icon = 'icons/mob/inhands/items/books_lefthand.dmi'
	/// The righthand icon file to use for the bible
	var/bible_righthand_icon = 'icons/mob/inhands/items/books_righthand.dmi'
	/// The inhand icon state to use for the bible
	var/bible_inhand_icon_state = "bible"

/**
 * Applies this bible skin to the target bible
 *
 * Arguments
 * * Reskinner - optional, who's doing the reskin. Some skins apply effects when selected
 * * Reskinned - required, what's being reskinnied. It's a bible.
 */
/datum/bible_skin/proc/apply_reskin(mob/living/carbon/human/reskinner, obj/item/book/bible/reskinned)
	// If there's a global name, don't override it, use it instead
	if(GLOB.bible_name)
		reskinned.name = GLOB.bible_name
	// Otherwise use our name if set
	else if(name)
		reskinned.name = name

	// If there's a global deity, don't override it, use it instead
	if(GLOB.deity)
		reskinned.deity_name = GLOB.deity
	// Otherwise use our deity if set
	else if(deity_name)
		reskinned.deity_name = deity_name

	reskinned.icon = bible_icon
	reskinned.icon_state = bible_icon_state
	reskinned.lefthand_file = bible_lefthand_icon
	reskinned.righthand_file = bible_righthand_icon
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
