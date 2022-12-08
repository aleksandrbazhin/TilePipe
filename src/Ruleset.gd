class_name Ruleset
extends Resource


enum ERRORS {
	OK,
	OLD_FORMAT,
	WRONG_FILE,
	INVALID_JSON,
	SCHEMA_MISMATCH
}

var ERROR_MESSAGES := {
	ERRORS.OK: "Ok!",
	ERRORS.OLD_FORMAT: "Wrong (old) ruleset format",
	ERRORS.WRONG_FILE: "Data loader error: invalid path to ruleset JSON in .tptile.\n",
	ERRORS.INVALID_JSON: "Data loader error: invalid JSON.\n",
	ERRORS.SCHEMA_MISMATCH: "Data loader error: schema mismatch."
}

enum RULESET_TILE_PARTS {
	FULL, 
	SIDE_TOP, 
	SIDE_RIGHT,
	SIDE_BOTTOM,
	SIDE_LEFT,
	CORNER_IN_TOP_RIGHT,
	CORNER_IN_BOTTOM_RIGHT,
	CORNER_IN_BOTTOM_LEFT,
	CORNER_IN_TOP_LEFT,
	CORNER_OUT_TOP_RIGHT,
	CORNER_OUT_BOTTOM_RIGHT,
	CORNER_OUT_BOTTOM_LEFT,
	CORNER_OUT_TOP_LEFT,
}
const RULESET_PART_OVERLAP_VECTORS := {
	RULESET_TILE_PARTS.FULL: Vector2.ZERO,
	RULESET_TILE_PARTS.SIDE_TOP: Vector2(0, 1),
	RULESET_TILE_PARTS.SIDE_RIGHT: Vector2(1, 0),
	RULESET_TILE_PARTS.SIDE_BOTTOM: Vector2(0, 1),
	RULESET_TILE_PARTS.SIDE_LEFT: Vector2(1, 0),
	RULESET_TILE_PARTS.CORNER_IN_TOP_RIGHT: Vector2(-1, -1),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_RIGHT: Vector2(-1, -1),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_LEFT: Vector2(-1, -1),
	RULESET_TILE_PARTS.CORNER_IN_TOP_LEFT: Vector2(-1, -1),
	RULESET_TILE_PARTS.CORNER_OUT_TOP_RIGHT: Vector2(1, 1),
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_RIGHT: Vector2(1, 1),
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_LEFT: Vector2(1, 1),
	RULESET_TILE_PARTS.CORNER_OUT_TOP_LEFT: Vector2(1, 1),
}
const RULESET_PART_TEXTURES := {
	RULESET_TILE_PARTS.FULL: preload("res://assets/images/ruleset_icons/ruleset_tile_full.png"), 
	RULESET_TILE_PARTS.SIDE_TOP: preload("res://assets/images/ruleset_icons/ruleset_tile_top.png"),
	RULESET_TILE_PARTS.SIDE_RIGHT: preload("res://assets/images/ruleset_icons/ruleset_tile_right.png"),
	RULESET_TILE_PARTS.SIDE_BOTTOM: preload("res://assets/images/ruleset_icons/ruleset_tile_bottom.png"),
	RULESET_TILE_PARTS.SIDE_LEFT: preload("res://assets/images/ruleset_icons/ruleset_tile_left.png"),
	RULESET_TILE_PARTS.CORNER_IN_TOP_RIGHT: preload("res://assets/images/ruleset_icons/ruleset_tile_in_top_right.png"),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_RIGHT: preload("res://assets/images/ruleset_icons/ruleset_tile_in_bottom_right.png"),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_LEFT: preload("res://assets/images/ruleset_icons/ruleset_tile_in_bottom_left.png"),
	RULESET_TILE_PARTS.CORNER_IN_TOP_LEFT: preload("res://assets/images/ruleset_icons/ruleset_tile_in_top_left.png"),
	RULESET_TILE_PARTS.CORNER_OUT_TOP_RIGHT: preload("res://assets/images/ruleset_icons/ruleset_tile_out_top_right.png"),
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_RIGHT: preload("res://assets/images/ruleset_icons/ruleset_tile_out_bottom_right.png"), 
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_LEFT: preload("res://assets/images/ruleset_icons/ruleset_tile_out_bottom_left.png"), 
	RULESET_TILE_PARTS.CORNER_OUT_TOP_LEFT: preload("res://assets/images/ruleset_icons/ruleset_tile_out_top_left.png"),
}
const PART_HIGHLIGHT_MASKS := {
	RULESET_TILE_PARTS.FULL: preload("res://assets/images/part_masks/tile_full.png"), 
	RULESET_TILE_PARTS.SIDE_TOP: preload("res://assets/images/part_masks/tile_top.png"),
	RULESET_TILE_PARTS.SIDE_RIGHT: preload("res://assets/images/part_masks/tile_right.png"),
	RULESET_TILE_PARTS.SIDE_BOTTOM: preload("res://assets/images/part_masks/tile_bottom.png"),
	RULESET_TILE_PARTS.SIDE_LEFT: preload("res://assets/images/part_masks/tile_left.png"),
	RULESET_TILE_PARTS.CORNER_IN_TOP_RIGHT: preload("res://assets/images/part_masks/tile_in_top_right.png"),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_RIGHT: preload("res://assets/images/part_masks/tile_in_bottom_right.png"),
	RULESET_TILE_PARTS.CORNER_IN_BOTTOM_LEFT: preload("res://assets/images/part_masks/tile_in_bottom_left.png"),
	RULESET_TILE_PARTS.CORNER_IN_TOP_LEFT: preload("res://assets/images/part_masks/tile_in_top_left.png"),
	RULESET_TILE_PARTS.CORNER_OUT_TOP_RIGHT: preload("res://assets/images/part_masks/tile_out_top_right.png"),
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_RIGHT: preload("res://assets/images/part_masks/tile_out_bottom_right.png"), 
	RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_LEFT: preload("res://assets/images/part_masks/tile_out_bottom_left.png"), 
	RULESET_TILE_PARTS.CORNER_OUT_TOP_LEFT: preload("res://assets/images/part_masks/tile_out_top_left.png"),
}
const SCHEMA_PATH := "res://rulesets/ruleset_schema.json"
const PREVIEW_SIZE_PX := 48
const PREVIEW_SPACE_PX := 6
const RULESET_TILE_PARSE_DATA := {
	"FULL": RULESET_TILE_PARTS.FULL, 
	"SIDE_TOP": RULESET_TILE_PARTS.SIDE_TOP,
	"SIDE_RIGHT": RULESET_TILE_PARTS.SIDE_RIGHT,
	"SIDE_BOTTOM": RULESET_TILE_PARTS.SIDE_BOTTOM,
	"SIDE_LEFT": RULESET_TILE_PARTS.SIDE_LEFT,
	"CORNER_IN_TOP_RIGHT": RULESET_TILE_PARTS.CORNER_IN_TOP_RIGHT,
	"CORNER_IN_BOTTOM_RIGHT": RULESET_TILE_PARTS.CORNER_IN_BOTTOM_RIGHT,
	"CORNER_IN_BOTTOM_LEFT": RULESET_TILE_PARTS.CORNER_IN_BOTTOM_LEFT,
	"CORNER_IN_TOP_LEFT": RULESET_TILE_PARTS.CORNER_IN_TOP_LEFT,
	"CORNER_OUT_TOP_RIGHT": RULESET_TILE_PARTS.CORNER_OUT_TOP_RIGHT,
	"CORNER_OUT_BOTTOM_RIGHT": RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_RIGHT,
	"CORNER_OUT_BOTTOM_LEFT": RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_LEFT,
	"CORNER_OUT_TOP_LEFT": RULESET_TILE_PARTS.CORNER_OUT_TOP_LEFT,
}

var _data := {}
var _raw_json: String
var _raw_tile_data: PoolStringArray
var is_loaded := false
var last_error := -1
var last_error_message := ""

var preview_texture: Texture
var parts := []


func _init(data_path: String):
	load_data_from_json(data_path)
	preview_texture = generate_preview()


func validate_ruleset_json_to_schema(_json_data: Dictionary) -> int:
	if not _json_data.has("rules"):
		return ERRORS.OLD_FORMAT
#	tests:
#	1. everything is according to schema
#	2. part_indexes are never greater than tile_parts array size
#	3. every mask is not used more than once
	return ERRORS.OK


func load_data_from_json(data_path: String):
	var data_file = File.new()
	if data_file.file_exists(data_path):
		data_file.open(data_path, File.READ)
		var data_string: String = data_file.get_as_text()
		data_file.close()
		var json_error := validate_json(data_string)
		if json_error == "":
			var parse_result: JSONParseResult = JSON.parse(data_string)
			if parse_result.error == OK:
				var validate_error := validate_ruleset_json_to_schema(parse_result.result)
				if validate_error == ERRORS.OK:
					_data = parse_result.result
					_raw_json = data_string
					_raw_tile_data = split_data_into_tiles(data_string)
					is_loaded = true
				else:
					last_error = validate_error
					json_error = ERROR_MESSAGES[validate_error]
					last_error_message += json_error
			else:
				last_error = ERRORS.INVALID_JSON
				last_error_message =  ERROR_MESSAGES[ERRORS.INVALID_JSON]
				last_error_message += "Path to json:\n" + data_path + "\n"
		else:
			last_error = ERRORS.INVALID_JSON
			last_error_message = ERROR_MESSAGES[ERRORS.INVALID_JSON]
			last_error_message += "Path to json:\n" + data_path + "\n"
			last_error_message += "Error message:\n" + json_error + "\n"
	else:
		last_error = ERRORS.WRONG_FILE
		last_error_message = ERROR_MESSAGES[ERRORS.WRONG_FILE]
		last_error_message += "Invalid path: " + data_path + "\n"
	
	if _data.has("tile_parts"):
		parts = parse_parts(_data["tile_parts"])
	elif last_error == ERRORS.OK:
		last_error = ERRORS.SCHEMA_MISMATCH
		last_error_message = ERROR_MESSAGES[ERRORS.SCHEMA_MISMATCH]


func parse_parts(raw_data: Array) -> Array:
	var parsed_parts = []
	for part in raw_data:
		if part in RULESET_TILE_PARSE_DATA:
			parsed_parts.append(RULESET_TILE_PARSE_DATA[part])
	return parsed_parts


func get_subtiles() -> Array:
	if _data.has("rules"):
		return _data["rules"]
	else:
		last_error = ERRORS.SCHEMA_MISMATCH
		last_error_message = ERROR_MESSAGES[ERRORS.SCHEMA_MISMATCH]
		return []


func get_name() -> String:
	if _data.has("ruleset_name"):
		return _data["ruleset_name"]
	else:
		last_error = ERRORS.SCHEMA_MISMATCH
		last_error_message = ERROR_MESSAGES[ERRORS.SCHEMA_MISMATCH]
		return "Error:"


func get_description() -> String:
	if _data.has("ruleset_description"):
		return _data["ruleset_description"]
	else:
		last_error = ERRORS.SCHEMA_MISMATCH
		last_error_message = ERROR_MESSAGES[ERRORS.SCHEMA_MISMATCH]
		return ""


func get_mask_data(mask: int) -> Dictionary:
	for tile_data in get_subtiles():
		if tile_data["mask_variants"].has(float(mask)):
			return tile_data
	last_error_message = ERROR_MESSAGES[ERRORS.SCHEMA_MISMATCH]
	last_error_message += "Invalid mask '%s'" % mask
#	print("ERROR: invalid mask '%s'" % mask)
	return {}


func generate_preview() -> Texture:
#	var parts := get_parts()
	if not parts.empty():
		var format: int = RULESET_PART_TEXTURES[parts[0]].get_data().get_format()
		var image := Image.new()
		image.create(PREVIEW_SIZE_PX * parts.size() + PREVIEW_SPACE_PX * parts.size() - 1, PREVIEW_SIZE_PX, false, format)
		var part_copy_rect := Rect2(Vector2.ZERO, Vector2(PREVIEW_SIZE_PX, PREVIEW_SIZE_PX))
		var part_index := 0
		for part in parts:
			var part_image: Image = RULESET_PART_TEXTURES[part].get_data() 
			image.blit_rect(part_image, part_copy_rect, Vector2(part_index * (PREVIEW_SIZE_PX + PREVIEW_SPACE_PX), 0))
			part_index += 1
		var itex := ImageTexture.new()
		itex.create_from_image(image)
		return itex
	else:
		return ImageTexture.new()


func get_raw_header() -> String:
	var end_of_header := _raw_json.find('"rules": ')
	if end_of_header != -1:
		return _raw_json.substr(0, end_of_header).lstrip("{").rstrip(", \n")
	return ""


func get_raw_tile_data(tile_index: int) -> String:
	if not _raw_tile_data.empty() and _raw_tile_data.size() > tile_index:
		return _raw_tile_data[tile_index].lstrip("{[\n").trim_prefix("        {").\
			rstrip(" \n}").trim_suffix("        }\n    ]").rstrip("\n").lstrip("\n")
	return ""


func split_data_into_tiles(data: String) -> PoolStringArray:
	var result: PoolStringArray
	var end_of_header := _raw_json.find('rules":')
	if end_of_header != -1:
		result = _raw_json.substr(end_of_header + 9).split("},")
	return result
