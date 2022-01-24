extends Resource

class_name Ruleset

const SCHEMA_PATH := "res://rulesets/ruleset_schema.json"

enum {ERROR_WRONG_FILE, ERROR_INVALID_JSON, ERROR_SCHEMA_MISMATCH}

var _data := {}
var is_loaded := false
var last_error := -1
var last_error_message := ""


func _init(data_path: String):
	load_data_from_json(data_path)
	


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
		last_error_message += "Invalid path:" + data_path + "\n"
		print(last_error_message)


func get_tile_parts() -> Array:
	return _data["tile_parts"]


func get_tiles() -> Array:
	return _data["tiles"]

#
#func get_ruleset() -> Dictionary:
#	return _data


func get_name() -> String:
	return _data["ruleset_name"]


func get_description() -> String:
	return _data["description"]


func get_input_size() -> int:
	return _data["input_parts"].size()


func get_mask_data(mask: int) -> Dictionary:
	for tile_data in get_tiles():
		if tile_data["mask_variants"].has(float(mask)):
			return tile_data
	print("ERROR: invalid mask '%s'" % mask)
	return {}
