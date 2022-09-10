class_name Ruleset
extends Resource

enum {ERROR_WRONG_FILE, ERROR_INVALID_JSON, ERROR_SCHEMA_MISMATCH}
const SCHEMA_PATH := "res://rulesets/ruleset_schema.json"
const PREVIEW_SIZE_PX := 48
const PREVIEW_SPACE_PX := 6
const RULESET_TILE_PARSE_DATA := {
	"FULL": Const.RULESET_TILE_PARTS.FULL, 
	"SIDE_TOP": Const.RULESET_TILE_PARTS.SIDE_TOP,
	"SIDE_RIGHT": Const.RULESET_TILE_PARTS.SIDE_RIGHT,
	"SIDE_BOTTOM": Const.RULESET_TILE_PARTS.SIDE_BOTTOM,
	"SIDE_LEFT": Const.RULESET_TILE_PARTS.SIDE_LEFT,
	"CORNER_IN_TOP_RIGHT": Const.RULESET_TILE_PARTS.CORNER_IN_TOP_RIGHT,
	"CORNER_IN_BOTTOM_RIGHT": Const.RULESET_TILE_PARTS.CORNER_IN_BOTTOM_RIGHT,
	"CORNER_IN_BOTTOM_LEFT": Const.RULESET_TILE_PARTS.CORNER_IN_BOTTOM_LEFT,
	"CORNER_IN_TOP_LEFT": Const.RULESET_TILE_PARTS.CORNER_IN_TOP_LEFT,
	"CORNER_OUT_TOP_RIGHT": Const.RULESET_TILE_PARTS.CORNER_OUT_TOP_RIGHT,
	"CORNER_OUT_BOTTOM_RIGHT": Const.RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_RIGHT,
	"CORNER_OUT_BOTTOM_LEFT": Const.RULESET_TILE_PARTS.CORNER_OUT_BOTTOM_LEFT,
	"CORNER_OUT_TOP_LEFT": Const.RULESET_TILE_PARTS.CORNER_OUT_TOP_LEFT
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


func validate_ruleset_json_to_schema(_json_data: Dictionary) -> String:
#	tests:
#	1. everything is according to schema
#	2. part_indexes are never greater than tile_parts array size
#	3. every mask is not used more than once
	return ""


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
				json_error = validate_ruleset_json_to_schema(parse_result.result)
				if json_error == "":
					_data = parse_result.result
					_raw_json = data_string
					_raw_tile_data = split_data_into_tiles(data_string)
					is_loaded = true
				else:
					last_error = ERROR_SCHEMA_MISMATCH
					last_error_message = "Data loader error: schema mismatch. Error message:\n"
					last_error_message += json_error + "\n"
					print(last_error_message)
			else:
				last_error = ERROR_INVALID_JSON
				last_error_message = "Data loader error: invalid JSON.\n" 
				last_error_message += "Path to json:\n" + data_path + "\n"
				print(last_error_message)
		else:
			last_error = ERROR_INVALID_JSON
			last_error_message = "Data loader error: invalid JSON.\n" 
			last_error_message += "Path to json:\n" + data_path + "\n"
			last_error_message += "Error message:\n" + json_error + "\n"
			print(last_error_message)
	else:
		last_error = ERROR_WRONG_FILE
		last_error_message = "Data loader error: invalid path to ruleset JSON in .tptile.\n" 
		last_error_message += "Invalid path: " + data_path + "\n"
		print(last_error_message)

	if _data.has("tile_parts"):
		parts = parse_parts(_data["tile_parts"])
	else:
		last_error = ERROR_SCHEMA_MISMATCH
		last_error_message = "Error: wrong ruleset format."
		print(last_error_message)


func parse_parts(raw_data: Array) -> Array:
	var parsed_parts = []
	for part in raw_data:
		if part in RULESET_TILE_PARSE_DATA:
			parsed_parts.append(RULESET_TILE_PARSE_DATA[part])
		else:
			print(parts)
	return parsed_parts

#
#func get_parts() -> Array:
#	if _data.has("tile_parts"):
#		return _data["tile_parts"]
#	else:
#		last_error = ERROR_SCHEMA_MISMATCH
#		last_error_message = "Error: wrong ruleset format."
#		return []
#

func get_subtiles() -> Array:
	if _data.has("tiles"):
		return _data["tiles"]
	else:
		last_error = ERROR_SCHEMA_MISMATCH
		last_error_message = "Error: wrong ruleset format."
		return []


func get_name() -> String:
	if _data.has("ruleset_name"):
		return _data["ruleset_name"]
	else:
		last_error = ERROR_SCHEMA_MISMATCH
		last_error_message = "Error: wrong ruleset format."
		return "Error:"


func get_description() -> String:
	if _data.has("ruleset_description"):
		return _data["ruleset_description"]
	else:
		last_error = ERROR_SCHEMA_MISMATCH
		last_error_message = "Error: wrong ruleset format."
		return ""


func get_mask_data(mask: int) -> Dictionary:
	for tile_data in get_subtiles():
		if tile_data["mask_variants"].has(float(mask)):
			return tile_data
	last_error_message = "Error: wrong ruleset format. \n"
	last_error_message += "Invalid mask '%s'" % mask
#	print("ERROR: invalid mask '%s'" % mask)
	return {}


func generate_preview() -> Texture:
#	var parts := get_parts()
	if not parts.empty():
		var format: int = Const.RULESET_PART_TEXTURES[parts[0]].get_data().get_format()
		var image := Image.new()
		image.create(PREVIEW_SIZE_PX * parts.size() + PREVIEW_SPACE_PX * parts.size() - 1, PREVIEW_SIZE_PX, false, format)
		var part_copy_rect := Rect2(Vector2.ZERO, Vector2(PREVIEW_SIZE_PX, PREVIEW_SIZE_PX))
		var part_index := 0
		for part in parts:
			var part_image: Image = Const.RULESET_PART_TEXTURES[part].get_data() 
			image.blit_rect(part_image, part_copy_rect, Vector2(part_index * (PREVIEW_SIZE_PX + PREVIEW_SPACE_PX), 0))
			part_index += 1
		var itex := ImageTexture.new()
		itex.create_from_image(image)
		return itex
	else:
		return ImageTexture.new()


func get_raw_header() -> String:
	var end_of_header := _raw_json.find('"tiles":')
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
	var end_of_header := _raw_json.find('"tiles":')
	if end_of_header != -1:
		result = _raw_json.substr(end_of_header + 9).split("},")
	return result
