//rune colors, for easy reference
#define RUNE_COLOR_TALISMAN "#0000FF"
#define RUNE_COLOR_TELEPORT "#551A8B"
#define RUNE_COLOR_OFFER "#FFFFFF"
#define RUNE_COLOR_DARKRED "#7D1717"
#define RUNE_COLOR_MEDIUMRED "#C80000"
#define RUNE_COLOR_BURNTORANGE "#CC5500"
#define RUNE_COLOR_RED "#FF0000"
#define RUNE_COLOR_EMP "#4D94FF"
#define RUNE_COLOR_SUMMON "#00FF00"

/// Ratio of living cultists to living non-cultists needed for the cult to gain glowing red eyes
/// This is not a "% of living players that are cultists", this is a RATIO of CULTISTS to NON-CULTISTS
#define CULT_RISEN 0.2
/// Ratio of living cultists to living non-cultists needed for the cult to gain glowing huge red halos
/// This is not a "% of living players that are cultists", this is a RATIO of CULTISTS to NON-CULTISTS
#define CULT_ASCENDENT 0.4

//screen locations
#define DEFAULT_BLOODSPELLS "6:-29,4:-2"
#define DEFAULT_BLOODTIP "14:6,14:27"
#define DEFAULT_TOOLTIP "6:-29,5:-2"
//misc
#define SOULS_TO_REVIVE 3
#define BLOODCULT_EYE "#FF0000"
//soulstone & construct themes
#define THEME_CULT "cult"
#define THEME_WIZARD "wizard"
#define THEME_HOLY "holy"

/// Defines for cult item_dispensers.
#define PREVIEW_IMAGE "preview"
#define OUTPUT_ITEMS "output"

/// The global Nar'sie that the cult's summoned
GLOBAL_DATUM(cult_narsie, /obj/narsie)

// Used in determining which cinematic to play when cult ends
#define CULT_VICTORY_MASS_CONVERSION 2
#define CULT_FAILURE_NARSIE_KILLED 1
#define CULT_VICTORY_NUKE 0

/// Global list of all cult spells typepaths a blood cultist can carve and learn.
GLOBAL_LIST_INIT(cult_spell_types, list(
	/datum/action/cooldown/spell/aoe/veiling,
	/datum/action/cooldown/spell/emp/cult,
	/datum/action/cooldown/spell/pointed/horrors,
	/datum/action/cooldown/spell/summon_cult_dagger,
	/datum/action/cooldown/spell/touch/blood_rites,
	/datum/action/cooldown/spell/touch/cult_armor,
	/datum/action/cooldown/spell/touch/cult_shackles,
	/datum/action/cooldown/spell/touch/cult_stun,
	/datum/action/cooldown/spell/touch/cult_teleport,
	/datum/action/cooldown/spell/touch/twisted_construction,
))

/**
 * Helper macro for defining an action as a cult action
 *
 * Handles assigning the check flags and the button icon / style to look as it should for a cult action
 */
#define DEFINE_CULT_ACTION(icon_state, icon) \
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS; \
	button_icon = icon; \
	button_icon_state = icon_state; \
	background_icon_state = "bg_demon"; \
	overlay_icon_state = "bg_demon_border"; \
	buttontooltipstyle = "cult"; \
