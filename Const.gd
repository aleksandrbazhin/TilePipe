extends Node

const SETTINGS_PATH := "user://user_settings.sav"
const TILE_SETTINGS_DIR := "user://tile_settings"
# version comparison works in godot due to str comparison (is_str_les() in ustring.h)
const MIN_SETTINGS_COMPATIBLE_VERSION: String = "0.2"

const FULL_HD := Vector2(1920, 1080)

const NO_SCALING: int = 0
const OUTPUT_SIZES: Dictionary = {
	NO_SCALING: "No scaling",
	8: "8x8",
	10: "10x10",
	16: "16x16",
	20: "20x20",
	24: "24x24",
	32: "32x32",
	40: "40x40",
	48: "48x48",
	64: "64x64",
	80: "80x80",
	96: "96x96",
	100: "100x100",
	128: "128x128"
}
const TEMPLATE_TILE_SIZE: int = 32
const DEFAULT_OUTPUT_SIZE: int = 64

const TILE_SAVE_SUFFIX: String = "_generated"

enum COLOR_PROCESS_TYPES {NO, FLOW_MAP}#, NORMAL_MAP
const COLOR_PROCESS_TYPE_NAMES: Dictionary = {
	COLOR_PROCESS_TYPES.NO: "No processing",
	COLOR_PROCESS_TYPES.FLOW_MAP: "Flow map",
#	COLOR_PROCESS_TYPES.NORMAL_MAP: "Normal map",
}
enum INPUT_TYPES {CORNERS, OVERLAY}
const INPUT_TYPE_NAMES : Dictionary = {
	INPUT_TYPES.CORNERS: "Quarters",
	INPUT_TYPES.OVERLAY: "Overlay"
}

enum CORNERS_INPUT_PRESETS {
	FIVE, 
	FOUR
}
const CORNERS_INPUT_PRESETS_NAMES: Dictionary = {
	CORNERS_INPUT_PRESETS.FIVE: "5 quarters, symmety: full",
	CORNERS_INPUT_PRESETS.FOUR: "4 quarters, symmety: full",
}
const CORNERS_INPUT_PRESETS_DATA_PATH: Dictionary = {
	CORNERS_INPUT_PRESETS.FIVE: "res://generation_data/quarters_5.json",
	CORNERS_INPUT_PRESETS.FOUR: "res://generation_data/quarters_4.json",
}

enum OVERLAY_INPUT_PRESETS {
#	TOP_DOWN_2, 
#	TOP_DOWN_3, 
	TOP_DOWN_4, 
#	SIDEVIEW_6, 
	SIDEVIEW_8,
	SIDEVIEW_13,
	SIDEVIEW_25_255,
	SIDEVIEW_7_255,
}
const OVERLAY_INPUT_PRESET_NAMES: Dictionary = {
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_2: "Top down without corners (2 tiles)",
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_3: "Top down with corners (3 tiles)",
	OVERLAY_INPUT_PRESETS.TOP_DOWN_4: "4 parts, symmetry: full",
#	OVERLAY_INPUT_PRESETS.SIDEVIEW_6: "Sideview (6 tiles)",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_8: "8 parts, symmetry: sideway",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_13: "13 parts, symmetry: no",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_25_255: "Full 255 tile template (25 parts)",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_7_255: "Symmetrical 255 tile template (7 parts)",
}

const OVERLAY_INPUT_PRESETS_DATA_PATH: Dictionary = {
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_2: "res://generation_data/overlay_2.json",
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_3: "res://generation_data/overlay_3.json",
	OVERLAY_INPUT_PRESETS.TOP_DOWN_4: "res://generation_data/overlay_4_full.json",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_8: "res://generation_data/overlay_8_full.json",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_13: "res://generation_data/overlay_13_full.json",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_25_255: "res://generation_data/overlay_255_no_symmetry.json",
	OVERLAY_INPUT_PRESETS.SIDEVIEW_7_255: "res://generation_data/overlay_255_full_symmetry.json",
}

enum TEMPLATE_TYPES {BLOB_47, BLOB_255, CORNERS_2x2, BLOB_47_MR_MICHAEL, RPG_MAKER, BLOB_47x2, CUSTOM}
const TEMPLATE_TYPE_NAMES : Dictionary = {
	TEMPLATE_TYPES.BLOB_47: "Blob 47 (3x3min)",
	TEMPLATE_TYPES.BLOB_255: "Blob 255 tiles (3x3)",
	TEMPLATE_TYPES.CORNERS_2x2: "Wang corners 16 (2x2)",
	TEMPLATE_TYPES.BLOB_47x2: "Double blob (for random)",
	TEMPLATE_TYPES.BLOB_47_MR_MICHAEL: "Big blob from MrMichael",
	TEMPLATE_TYPES.RPG_MAKER: "Rpg-maker style",
	TEMPLATE_TYPES.CUSTOM: "Custom"
}
const TEMPLATE_PATHS : Dictionary = {
	TEMPLATE_TYPES.BLOB_47: "res://generation_data/template_47.png",
	TEMPLATE_TYPES.BLOB_255: "res://generation_data/template_255.png",
	TEMPLATE_TYPES.CORNERS_2x2: "res://generation_data/template_2x2.png",
	TEMPLATE_TYPES.BLOB_47x2: "res://generation_data/template_47_double.png",
	TEMPLATE_TYPES.BLOB_47_MR_MICHAEL: "res://generation_data/template_47_with_duplicates.png",
	TEMPLATE_TYPES.RPG_MAKER: "res://generation_data/template_rpg_maker.png",
	TEMPLATE_TYPES.CUSTOM: "res://"
}

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
const DEFAULT_INPUT_TEXTURE_PATH: String = "res://generation_data/quarters_5.png"
const DEFAULT_GODOT_RESOURCE_PATH := "res://tileset.tres"
const DEFAULT_GODOT_TEXTURE_PATH := "res://generated_autotile.png"

const COMMON_DEFAULT_SETTINGS: Dictionary = {
	"program_version": "0.2",
	
	
}



const TILE_SPECIFIC_DEFAULT_SETTINGS: Dictionary = {
	
	"last_texture_path": DEFAULT_INPUT_TEXTURE_PATH,
	"last_gen_preset_path": CORNERS_INPUT_PRESETS_DATA_PATH[CORNERS_INPUT_PRESETS.FIVE],
	"last_template_path": TEMPLATE_PATHS[TEMPLATE_TYPES.BLOB_47],
	"last_save_texture_path": "res://generated_tile_texture.png",
	"last_texture_file_dialog_path": DEFAULT_INPUT_TEXTURE_PATH,
	"last_template_file_dialog_path": TEMPLATE_PATHS[TEMPLATE_TYPES.BLOB_47],
	"output_tile_size": DEFAULT_OUTPUT_SIZE,
	"input_type": 0,
	"corner_preset": 0,
	"overlay_preset": 0,
	"template_type": 0,
	"smoothing": false,
	"merge_level": DEFAULT_MERGE,
	"overlap_level": DEFAULT_OVERLAP,
	"use_random_seed": false,
	"random_seed_value": 0,
	"output_tile_offset": 0,
	"use_example": true,
	"godot_export_resource_path": DEFAULT_GODOT_RESOURCE_PATH,
	"godot_export_texture_path": DEFAULT_GODOT_TEXTURE_PATH,
	"godot_export_tile_name": "",
	"godot_export_last_generated_tile_name": "",
	"godot_autotile_type": GODOT_AUTOTILE_TYPE.BLOB_3x3	
}

# IMPORTANT!
# When some setting kind radically changes, 
# change MIN_SETTINGS_COMPATIBLE_VERSION to current version from override.cfg.
# Adding new setting does not require MIN_SETTINGS_COMPATIBLE_VERSION change
const DEFAULT_SETTINGS: Dictionary = {
	"program_version": "0.2",
	"last_texture_path": DEFAULT_INPUT_TEXTURE_PATH,
	"last_gen_preset_path": CORNERS_INPUT_PRESETS_DATA_PATH[CORNERS_INPUT_PRESETS.FIVE],
	"last_template_path": TEMPLATE_PATHS[TEMPLATE_TYPES.BLOB_47],
	"last_save_texture_path": "res://generated_autotile.png",
	"last_texture_file_dialog_path": DEFAULT_INPUT_TEXTURE_PATH,
	"last_template_file_dialog_path": TEMPLATE_PATHS[TEMPLATE_TYPES.BLOB_47],
	"output_tile_size": DEFAULT_OUTPUT_SIZE,
	"input_type": 0,
	"corner_preset": 0,
	"overlay_preset": 0,
	"template_type": 0,
	"smoothing": false,
	"merge_level": DEFAULT_MERGE,
	"overlap_level": DEFAULT_OVERLAP,
	"use_random_seed": false,
	"random_seed_value": 0,
	"output_tile_offset": 0,
	"use_example": true,
	"godot_export_resource_path": DEFAULT_GODOT_RESOURCE_PATH,
	"godot_export_texture_path": DEFAULT_GODOT_TEXTURE_PATH,
	"godot_export_tile_name": "",
	"godot_export_last_generated_tile_name": "",
	"godot_autotile_type": GODOT_AUTOTILE_TYPE.BLOB_3x3

}



# key is bit lenght shift to rotate TEMPLATE_MASK_CHECK_POINTS to that angle
#const ROTATION_SHIFTS := {
#	0: {"vector": Vector2(1, 0), "angle": 0.0},
#	2: {"vector": Vector2(1, 1), "angle": PI / 2},
#	4: {"vector": Vector2(0, 1), "angle": PI},
#	6: {"vector": Vector2(0, 0), "angle": 3 * PI / 2},
#}
const ROTATION_SHIFTS := {
	0: {"vector": Vector2(0, 0), "angle": 0.0},
	2: {"vector": Vector2(1, 0), "angle": PI / 2},
	4: {"vector": Vector2(1, 1), "angle": PI},
	6: {"vector": Vector2(0, 1), "angle": 3 * PI / 2},
}
const FLIP_HORIZONTAL_KEYS := [0, 4]

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
