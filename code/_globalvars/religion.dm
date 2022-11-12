// All religion stuff
/// The chaplain's religion. String
GLOBAL_VAR(religion)
/// The chaplain's god. String
GLOBAL_VAR(deity)
/// The chaplain's sect. A religious sect, or null if unselected
GLOBAL_DATUM(religious_sect, /datum/religion_sect)

// Bible vars
/// The chaplain's preferred bible name
GLOBAL_VAR(bible_name)
/// A global list of [bible names] to [blible skin singletons]
GLOBAL_LIST_INIT(bible_names_to_skins, generate_bible_skins_by_name())
/// The currently selected bible skin by the chaplain, or null if unselected
GLOBAL_DATUM(current_bible_skin, /datum/bible_skin)

// Religious altars
/// A list of all chaplain altar of gods
GLOBAL_LIST_EMPTY(chaplain_altars)
/// A list of all religious tools, these are components
GLOBAL_LIST_EMPTY(religious_tools)

// Equipment
/// The holy weapon the chaplain selected out of their null rod
GLOBAL_VAR(holy_weapon_type)
/// The holy armaments the chaplain selected from their beacon
GLOBAL_VAR(holy_armor_type)

/// Default religion name
#define DEFAULT_RELIGION "Christianity"
/// Default deity name
#define DEFAULT_DEITY "Space Jesus"
/// Default bible skin, this one doesn't show up anywhere - just used as a key
#define DEFAULT_BIBLE_SKIN "Default Bible Skin"
/// Default bible name, same as above it doesn't show up anywhere - just used as a key
#define DEFAULT_BIBLE "Default Bible Name"
/// If the default bible name is chosen, the name actually becomes this.
#define DEFAULT_BIBLE_REPLACE(religion) "The Holy Book of [religion]"
