extends Node

const OUTPUT_SIZES: Dictionary = {
	8: "8x8",
	16: "16x16",
	32: "32x32",
	64: "64x64",
	128: "128x128"
}
const TEMPLATE_TILE_SIZE: int = 32
const DEFAULT_OUTPUT_SIZE: int = 64


enum COLOR_PROCESS_TYPES {NO, FLOW_MAP}#, NORMAL_MAP}
const COLOR_PROCESS_TYPE_NAMES: Dictionary = {
	COLOR_PROCESS_TYPES.NO: "No processing",
	COLOR_PROCESS_TYPES.FLOW_MAP: "Flow map",
#	COLOR_PROCESS_TYPES.NORMAL_MAP: "Normal map",
}
enum INPUT_TYPES {CORNERS, OVERLAY}
const INPUT_TYPE_NAMES : Dictionary = {
	INPUT_TYPES.CORNERS: "Quarters merge",
	INPUT_TYPES.OVERLAY: "Overlay"
}
const DEFAULT_INPUT_TYPE: int = INPUT_TYPES.CORNERS

enum CORNERS_INPUT_PRESETS {
	FIVE, 
	FOUR, 
#	NO
}
const CORNERS_INPUT_PRESETS_NAMES: Dictionary = {
	CORNERS_INPUT_PRESETS.FIVE: "5 quarters for 47-tile blob",
	CORNERS_INPUT_PRESETS.FOUR: "4 quarters for 47-tile blob",
#	CORNERS_INPUT_PRESETS.NO: "Custom preset",
}
const CORNERS_INPUT_PRESETS_EXAMPLES: Dictionary = {
	CORNERS_INPUT_PRESETS.FIVE: "res://generation_data/quarters_5.png",
	CORNERS_INPUT_PRESETS.FOUR: "res://generation_data/quarters_4.png",
#	CORNERS_INPUT_PRESETS.NO: "",
}
const CORNERS_INPUT_PRESETS_DATA_PATH: Dictionary = {
	CORNERS_INPUT_PRESETS.FIVE: "res://generation_data/quarters_5.json",
	CORNERS_INPUT_PRESETS.FOUR: "res://generation_data/quarters_4.json",
#	CORNERS_INPUT_PRESETS.NO: "",
}

enum OVERLAY_INPUT_PRESETS {
#	TOP_DOWN_2, 
#	TOP_DOWN_3, 
	TOP_DOWN_4, 
#	SIDEVIEW_6, 
#	SIDEVIEW_8
}
const OVERLAY_INPUT_PRESET_NAMES: Dictionary = {
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_2: "Top down without corners (2 tiles)",
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_3: "Top down with corners (3 tiles)",
	OVERLAY_INPUT_PRESETS.TOP_DOWN_4: "Top down with internal corner (4)",
#	OVERLAY_INPUT_PRESETS.SIDEVIEW_6: "Sideview (6 tiles)",
#	OVERLAY_INPUT_PRESETS.SIDEVIEW_8: "Sideview with internal corner (8)"
}
const OVERLAY_INPUT_EXAMPLES: Dictionary = {
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_2: "res://generation_data/overlay_2.png",
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_3: "res://generation_data/overlay_3.png",
	OVERLAY_INPUT_PRESETS.TOP_DOWN_4: "res://generation_data/overlay_4.png",
#	OVERLAY_INPUT_PRESETS.SIDEVIEW_6: "res://generation_data/input_overlay_3.png",
#	OVERLAY_INPUT_PRESETS.SIDEVIEW_8: "res://generation_data/input_overlay_3.png"
}
const OVERLAY_INPUT_PRESETS_DATA_PATH: Dictionary = {
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_2: "res://generation_data/overlay_2.json",
#	OVERLAY_INPUT_PRESETS.TOP_DOWN_3: "res://generation_data/overlay_3.json",
	OVERLAY_INPUT_PRESETS.TOP_DOWN_4: "res://generation_data/overlay_4.json",
#	CORNERS_INPUT_PRESETS.NO: "",
}
const TEMPLATE_47_PATH: String = "res://generation_data/template_47.png"
const TEMPLATE_256_PATH: String = "res://generation_data/template_256.png"
enum TEMPLATE_TYPES {TEMPLATE_47, CUSTOM}
#enum TEMPLATE_TYPES {TEMPLATE_47, TEMPLATE_256, CUSTOM}
const TEMPLATE_TYPE_NAMES : Dictionary = {
	TEMPLATE_TYPES.TEMPLATE_47: "Standard 3x3: 47",
#	TEMPLATE_TYPES.TEMPLATE_256: "Full 3x3: 256",
	TEMPLATE_TYPES.CUSTOM: "Custom 3x3"
}
const TEMPLATE_PATHS : Dictionary = {
	TEMPLATE_TYPES.TEMPLATE_47: TEMPLATE_47_PATH,
#	TEMPLATE_TYPES.TEMPLATE_256: TEMPLATE_256_PATH,
	TEMPLATE_TYPES.CUSTOM: "res://"
}

const SETTINGS_PATH: String = "user://settings.sav"

const MASK_TOP_LEFT := Vector2(4, 4)
const MASK_TOP := Vector2(16, 4)
const MASK_TOP_RIGHT := Vector2(28, 4)
const MASK_LEFT := Vector2(4, 16)
const MASK_CENTER := Vector2(16, 16)
const MASK_RIGHT := Vector2(28, 16)
const MASK_BOTTOM_LEFT := Vector2(4, 28)
const MASK_BOTTOM := Vector2(16, 28)
const MASK_BOTTOM_RIGHT := Vector2(28, 28)

const GODOT_MASK: Dictionary = {
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
const GODOT_MASK_CHECK_POINTS := {
	GODOT_MASK["TOP_LEFT"]: MASK_TOP_LEFT,
	GODOT_MASK["TOP"]: MASK_TOP,
	GODOT_MASK["TOP_RIGHT"]: MASK_TOP_RIGHT,
	GODOT_MASK["LEFT"]: MASK_LEFT,
	GODOT_MASK["CENTER"]: MASK_CENTER,
	GODOT_MASK["RIGHT"]: MASK_RIGHT,
	GODOT_MASK["BOTTOM_LEFT"]: MASK_BOTTOM_LEFT,
	GODOT_MASK["BOTTOM"]: MASK_BOTTOM,
	GODOT_MASK["BOTTOM_RIGHT"]: MASK_BOTTOM_RIGHT
}
# so it can be rotated by multiplication
const MY_MASK: Dictionary = {
	"TOP": 1,
	"TOP_RIGHT": 2,
	"RIGHT": 4,
	"BOTTOM_RIGHT": 8,
	"BOTTOM": 16,
	"BOTTOM_LEFT": 32,
	"LEFT": 64,
	"TOP_LEFT": 128,
}
#const MY_MASK_TRUE_ROTATIONS: Dictionary = {
#	"TOP": 0.0,
#	"TOP_RIGHT": PI / 4.0,
#	"RIGHT": PI / 2.0,
#	"BOTTOM_RIGHT": 3 * PI / 4.0,
#	"BOTTOM": PI,
#	"BOTTOM_LEFT": 5 * PI / 4.0,
#	"LEFT": 3 * PI / 2,
#	"TOP_LEFT": 7 * PI / 4.0,
#}
const TEMPLATE_MASK_CHECK_POINTS := {
	MY_MASK["TOP"]: MASK_TOP,
	MY_MASK["TOP_RIGHT"]: MASK_TOP_RIGHT,
	MY_MASK["RIGHT"]: MASK_RIGHT,
	MY_MASK["BOTTOM_RIGHT"]: MASK_BOTTOM_RIGHT,
	MY_MASK["BOTTOM"]: MASK_BOTTOM,
	MY_MASK["BOTTOM_LEFT"]: MASK_BOTTOM_LEFT,
	MY_MASK["LEFT"]: MASK_LEFT,
	MY_MASK["TOP_LEFT"]: MASK_TOP_LEFT
}

const DEFAULT_SETTINGS: Dictionary = {
	"last_texture_path": CORNERS_INPUT_PRESETS_EXAMPLES[CORNERS_INPUT_PRESETS.FIVE],
	"last_gen_preset_path": CORNERS_INPUT_PRESETS_DATA_PATH[CORNERS_INPUT_PRESETS.FIVE],
	"last_template_path": TEMPLATE_47_PATH,
	"last_save_texture_path": "res://generated.png",
	"last_save_texture_resource_path": "res://generated.tres",
	"output_tile_size": DEFAULT_OUTPUT_SIZE,
	"input_type": 0,
	"corner_preset": 0,
	"overlay_preset": 0
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
