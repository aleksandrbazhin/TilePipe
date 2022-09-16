extends Node


const SETTINGS_PATH := "user://settings.json"
const EXAMPLES_DIR := "examples"
const TILE_EXTENXSION := "tptile"
const MIN_WINDOW_SIZE := Vector2(800, 600)
const DRAG_END_MSEC := 200
const DEFAULT_TILE_SIZE := Vector2(64, 64)


const RULESET_DIR := "rulesets"
const TEMPLATE_DIR := "templates"

const HIGHLIGHT_COLORS := [
	Color("98c0ef"), 
	Color("f59d00"), 
	Color("1aaf5d"),
	Color("2278b2"),
	Color("c23824"),
	Color("9c56b8"),
	Color("3ca7fe"),
	Color("7f8c8d"),
	Color("58bb1e"),
	Color("d02365"),
	Color("1b5e04"),
	Color("0b2743"),
	Color("e0c01c")
]



const EXPORT_TYPE_UKNOWN := -1
enum EXPORT_TYPES {TEXTURE, GODOT3}

const GODOT3_UNKNOWN_AUTOTILE_TYPE := -1
enum GODOT_AUTOTILE_TYPE {BLOB_3x3, WANG_2x2, FULL_3x3}
const GODOT_AUTOTILE_TYPE_NAMES: Dictionary = {
	GODOT_AUTOTILE_TYPE.BLOB_3x3: "3X3 minimal",
	GODOT_AUTOTILE_TYPE.WANG_2x2: "2X2",
	GODOT_AUTOTILE_TYPE.FULL_3x3: "3x3 (255 tiles)",
}
const GODOT_AUTOTILE_GODOT_INDEXES: Dictionary = {
	GODOT_AUTOTILE_TYPE.BLOB_3x3: TileSet.BITMASK_3X3_MINIMAL,
	GODOT_AUTOTILE_TYPE.WANG_2x2: TileSet.BITMASK_2X2,
	GODOT_AUTOTILE_TYPE.FULL_3x3: TileSet.BITMASK_3X3
}

const TEMPLATE_TILE_SIZE: int = 32
const DEFAULT_OUTPUT_SIZE: int = 64

const TILE_SAVE_SUFFIX: String = "_tp"

const MASK_CHECK_TOP_LEFT := Vector2(4, 4)
const MASK_CHECK_TOP := Vector2(16, 4)
const MASK_CHECK_TOP_RIGHT := Vector2(28, 4)
const MASK_CHECK_LEFT := Vector2(4, 16)
const MASK_CHECK_CENTER := Vector2(16, 16)
const MASK_CHECK_RIGHT := Vector2(28, 16)
const MASK_CHECK_BOTTOM_LEFT := Vector2(4, 28)
const MASK_CHECK_BOTTOM := Vector2(16, 28)
const MASK_CHECK_BOTTOM_RIGHT := Vector2(28, 28)

# so it can be rotated by multiplication
const TILE_MASK: Dictionary = {
	"TOP": 1,
	"TOP_RIGHT": 2,
	"RIGHT": 4,
	"BOTTOM_RIGHT": 8,
	"BOTTOM": 16,
	"BOTTOM_LEFT": 32,
	"LEFT": 64,
	"TOP_LEFT": 128
}

const TEMPLATE_MASK_CHECK_POINTS := {
	TILE_MASK["TOP"]: MASK_CHECK_TOP,
	TILE_MASK["TOP_RIGHT"]: MASK_CHECK_TOP_RIGHT,
	TILE_MASK["RIGHT"]: MASK_CHECK_RIGHT,
	TILE_MASK["BOTTOM_RIGHT"]: MASK_CHECK_BOTTOM_RIGHT,
	TILE_MASK["BOTTOM"]: MASK_CHECK_BOTTOM,
	TILE_MASK["BOTTOM_LEFT"]: MASK_CHECK_BOTTOM_LEFT,
	TILE_MASK["LEFT"]: MASK_CHECK_LEFT,
	TILE_MASK["TOP_LEFT"]: MASK_CHECK_TOP_LEFT
}

const DEFAULT_MERGE: float = 0.25
const DEFAULT_OVERLAP: float = 0.25

# key is bit lenght shift to rotate TEMPLATE_MASK_CHECK_POINTS to that angle
const ROTATION_SHIFTS := {
	0: {"vector": Vector2(0, 0), "angle": 0.0},
	2: {"vector": Vector2(1, 0), "angle": PI / 2},
	4: {"vector": Vector2(1, 1), "angle": PI},
	6: {"vector": Vector2(0, 1), "angle": 3 * PI / 2},
}

const GODOT_MASK_3x3: Dictionary = {
	"TOP_LEFT": 1,
	"TOP": 2,
	"TOP_RIGHT": 4,
	"LEFT": 8,
	"CENTER": 16,
	"RIGHT": 32,
	"BOTTOM_LEFT": 64,
	"BOTTOM": 128,
	"BOTTOM_RIGHT": 256
}
const GODOT_MASK_2x2: Dictionary = {
	"TOP_LEFT": 1,
	"TOP_RIGHT": 4,
	"BOTTOM_LEFT": 64,
	"BOTTOM_RIGHT": 256
}
const GODOT_AUTOTILE_BITMASKS: Dictionary = {
	GODOT_AUTOTILE_TYPE.WANG_2x2: [112, 221, 7, 31, 127, 199, 28, 253, 255, 223, 119, 124, 247, 241, 193],
	GODOT_AUTOTILE_TYPE.BLOB_3x3: [16, 17, 1, 0, 20, 21, 5, 4, 84, 85, 69, 68, 80, 81, 65, 64, 213, 29, 23, 117, 92, 127, 223, 71, 116, 253, 247, 197, 87, 113, 209, 93, 28, 31, 95, 7, 125, 119, 255, 199, 124, 221, 215, 112, 245, 241, 193],
	GODOT_AUTOTILE_TYPE.FULL_3x3: [],
}


#enum COLOR_PROCESS_TYPES {NO, FLOW_MAP}#, NORMAL_MAP
#const COLOR_PROCESS_TYPE_NAMES: Dictionary = {
#	COLOR_PROCESS_TYPES.NO: "No processing",
#	COLOR_PROCESS_TYPES.FLOW_MAP: "Flow map",
##	COLOR_PROCESS_TYPES.NORMAL_MAP: "Normal map",
#}
