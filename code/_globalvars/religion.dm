// All religion stuff
GLOBAL_VAR(religion)
GLOBAL_VAR(deity)
GLOBAL_DATUM(religious_sect, /datum/religion_sect)

// Bible vars
GLOBAL_VAR(bible_name)
GLOBAL_LIST_INIT(bible_skins_to_images, generate_bible_skins_by_images())
GLOBAL_LIST_INIT(bible_skins_to_names, generate_bible_skins_by_name())
GLOBAL_DATUM(current_bible_skin, /datum/bible_skin)

// Religious altars
GLOBAL_LIST_EMPTY(chaplain_altars)

// Equipment
GLOBAL_VAR(holy_weapon_type)
GLOBAL_VAR(holy_armor_type)

#define DEFAULT_RELIGION "Christianity"
#define DEFAULT_DEITY "Space Jesus"
#define DEFAULT_BIBLE_SKIN "Default Bible Skin"
#define DEFAULT_BIBLE "Default Bible Name"
#define DEFAULT_BIBLE_REPLACE(religion) "The Holy Book of [religion]"
