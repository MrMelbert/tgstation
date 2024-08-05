// Byond direction defines, because I want to put them somewhere.
// #define NORTH 1
// #define SOUTH 2
// #define EAST 4
// #define WEST 8

/// North direction as a string "[1]"
#define TEXT_NORTH "[NORTH]"
/// South direction as a string "[2]"
#define TEXT_SOUTH "[SOUTH]"
/// East direction as a string "[4]"
#define TEXT_EAST "[EAST]"
/// West direction as a string "[8]"
#define TEXT_WEST "[WEST]"

//dir macros
///Returns true if the dir is diagonal, false otherwise
#define ISDIAGONALDIR(d) (d&(d-1))
///True if the dir is north or south, false therwise
#define NSCOMPONENT(d)   (d&(NORTH|SOUTH))
///True if the dir is east/west, false otherwise
#define EWCOMPONENT(d)   (d&(EAST|WEST))
///Flips the dir for north/south directions
#define NSDIRFLIP(d)     (d^(NORTH|SOUTH))
///Flips the dir for east/west directions
#define EWDIRFLIP(d)     (d^(EAST|WEST))

/// Inverse direction, taking into account UP|DOWN if necessary.
#define REVERSE_DIR(dir) ( ((dir & 85) << 1) | ((dir & 170) >> 1) )

// Wallening todo: temporary helper, until we finish fleshing things out and can convert the main one
// Why are we not just changing the sprites agian?
#define INVERT_MAPPING_DIRECTIONAL_HELPERS(path, offset) \
##path/directional/north {\
	dir = SOUTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (offset + WALL_OFFSET); \
} \
##path/directional/south {\
	dir = NORTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (-offset + WALL_OFFSET); \
} \
##path/directional/east {\
	dir = WEST; \
	pixel_x = offset; \
} \
##path/directional/west {\
	dir = EAST; \
	pixel_x = -offset; \
}

/// Directional helpers for things that use the wall_mount element
#define WALL_MOUNT_DIRECTIONAL_HELPERS(path) _WALL_MOUNT_DIRECTIONAL_HELPERS(path, 35, -8, 11, -11, 16)

#define SHOWER_DIRECTIONAL_HELPERS(path) _WALL_MOUNT_DIRECTIONAL_HELPERS(path, 32, -4, 16, -16, 12)

// Sinks need to be shifted down so they layer correctly when north due to their unique status
#define SINK_DIRECTIONAL_HELPERS(path) \
_WALL_MOUNT_DIRECTIONAL_HELPERS(path, 16, 24, 16, -16, 12) \
##path/directional/north {\
	pixel_y = -32; \
}

#define _WALL_MOUNT_DIRECTIONAL_HELPERS(path, north_offset, south_offset, east_offset, west_offset, horizontal_up_offset) \
##path/directional/north {\
	dir = SOUTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (north_offset + WALL_OFFSET); \
} \
##path/directional/south {\
	dir = NORTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (south_offset + WALL_OFFSET); \
} \
##path/directional/east {\
	dir = WEST; \
	pixel_x = east_offset; \
	MAP_SWITCH(pixel_z, pixel_y) = (horizontal_up_offset + WALL_OFFSET); \
} \
##path/directional/west {\
	dir = EAST; \
	pixel_x = west_offset; \
	MAP_SWITCH(pixel_z, pixel_y) = (horizontal_up_offset + WALL_OFFSET);  \
}

/// Directional helpers for cameras (cameras are really annoying)
/// They have diagonal dirs and also offset south differently
#define CAMERA_DIRECTIONAL_HELPERS(path) \
##path/directional/north {\
	dir = SOUTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (35 + WALL_OFFSET); \
} \
##path/directional/south {\
	dir = NORTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
} \
##path/directional/east {\
	dir = WEST; \
	pixel_x = 11; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
} \
##path/directional/west {\
	dir = EAST; \
	pixel_x = -11; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
} \
##path/directional/north_east {\
	dir = NORTHWEST; \
	MAP_SWITCH(pixel_z, pixel_y) = (35 + WALL_OFFSET); \
} \
##path/directional/north_west {\
	dir = NORTHEAST; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
} \
##path/directional/south_east {\
	dir = SOUTHWEST; \
	pixel_x = 11; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
} \
##path/directional/south_west {\
	dir = SOUTHEAST; \
	pixel_x = -11; \
	MAP_SWITCH(pixel_z, pixel_y) = (16 + WALL_OFFSET); \
}


/// Create directional subtypes for a path to simplify mapping.

#define MAPPING_DIRECTIONAL_HELPERS(path, offset) \
##path/directional/north {\
	dir = NORTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (offset + WALL_OFFSET); \
} \
##path/directional/south {\
	dir = SOUTH; \
	MAP_SWITCH(pixel_z, pixel_y) = (-offset + WALL_OFFSET); \
} \
##path/directional/east {\
	dir = EAST; \
	pixel_x = offset; \
} \
##path/directional/west {\
	dir = WEST; \
	pixel_x = -offset; \
}

#define MAPPING_DIRECTIONAL_HELPERS_EMPTY(path) \
##path/directional/north {\
	dir = NORTH; \
} \
##path/directional/south {\
	dir = SOUTH; \
} \
##path/directional/east {\
	dir = EAST; \
} \
##path/directional/west {\
	dir = WEST; \
}

#define BUTTON_DIRECTIONAL_HELPERS(path) \
##path/table { \
	on_table = TRUE; \
	icon_state = parent_type::icon_state + "_table"; \
	base_icon_state = parent_type::icon_state + "_table"; \
} \
WALL_MOUNT_DIRECTIONAL_HELPERS(path)
