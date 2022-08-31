extends Control

class_name TPTile

signal row_selected(row)

enum {
	PARAM_TEXTURE,
	PARAM_RULESET,
	PARAM_TEMPLATE,
	PARAM_INPUT_SIZE,
	PARAM_MERGE,
	PARAM_OVERLAP,
	PARAM_RANDOM_SEED_ENABLED,
	PARAM_RANDOM_SEED_VALUE,
	PARAM_SMOOTHING,
	PARAM_OUTPUT_SIZE,
	PARAM_SUBTILE_OFFSET,
	PARAM_EXPORT_TYPE,
	PARAM_EXPORT_PNG_PATH,
	PARAM_EXPORT_GODOT3_RESOURCE_PATH,
	PARAM_EXPORT_GODOT3_AUTTOTILE_TYPE,
	PARAM_EXPORT_GODOT3_TILE_NAME,
}


const HEIGHT_EXPANDED := 120
const HEIGHT_COLLAPSED := 50
const RULESET_PREFIX := "Ruleset: "
const TEXTURE_PREFIX := "Texture: "
const TEMPLATE_PREFIX := "Template: "
const EMPTY_TILE_CONTENT := {"texture": "", "ruleset": "", "template": ""}

var is_loaded := false
var _tile_data: Dictionary

var current_directory: String
var tile_file_name: String
var is_selected := false

var loaded_texture: Texture
var loaded_ruleset: Ruleset
var loaded_template: Texture
var result_subtiles_by_bitmask: Dictionary
var template_size: Vector2

var texture_path: String
var template_path: String
var ruleset_path: String
var input_tile_size: Vector2
var output_tile_size: Vector2 = Vector2(64,64)
var subtile_offset := Vector2.ZERO
var merge_level := Vector2(0.25, 0.25)
var overlap_level:= Vector2(0.25, 0.25)
var smoothing := false
var random_seed_enabled := false
var random_seed_value := 0
var export_type: int = Const.EXPORT_TYPE_UKNOWN
var export_png_path: String
var export_godot3_resource_path: String
var export_godot3_autotile_type: int = Const.GODOT3_UNKNOWN_AUTOTILE_TYPE
var export_godot3_tile_name: String


var tile_row: TreeItem
var ruleset_row: TreeItem
var template_row: TreeItem

var output_texture: Texture

onready var tree: Tree = $Tree
onready var highlight_rect := $ColorRect


func _ready():
	if is_loaded:
		create_tree_items()
		rect_min_size.y = HEIGHT_EXPANDED

# the purpose of this is to be able to add new parameters to .tptile in the future
# this way the program will still work, and will update the .tptile with defaults
func set_param(param_name: String, settings_param_name: String, default_value):
	if get(param_name) == null:
		print("Error: unknown tile parameter: ", param_name)
		return
	if settings_param_name in _tile_data:
		match typeof(get(param_name)):
			TYPE_VECTOR2:
				set(param_name, Vector2(_tile_data[settings_param_name]["x"],
										_tile_data[settings_param_name]["y"]))
			TYPE_INT:
				set(param_name, int(_tile_data[settings_param_name]))
			TYPE_BOOL:
				set(param_name, bool(_tile_data[settings_param_name]))
			TYPE_STRING:
				set(param_name, _tile_data[settings_param_name])
	else:
		if typeof(get(param_name)) == typeof(default_value):
			set(param_name, default_value)
		else:
			print("Error: setting parameter with default of wrong type")


func load_tile(directory: String, tile_file: String, is_new: bool = false) -> bool:
	current_directory = directory
	tile_file_name = tile_file
	var file_text := ""
	if is_new:
		file_text = JSON.print(EMPTY_TILE_CONTENT, "\t")
	else:
		var path := directory + "/" + tile_file
		var file := File.new()
		file.open(path, File.READ)
		file_text = file.get_as_text()
		file.close()
	var parsed_data = parse_json(file_text)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		State.report_error("Error loading tile: " + tile_file)
		block_failed_tile()
		return false
	_tile_data = parsed_data
	is_loaded = true
	var is_texture_loaded := load_texture(_tile_data["texture"])
	var is_ruleset_loaded := load_ruleset(_tile_data["ruleset"])
	var is_template_loaded := load_template(_tile_data["template"])
	set_param("input_tile_size", "input_tile_size", Const.DEFAULT_TILE_SIZE)
	set_param("merge_level", "merge_level", Vector2(0.25, 0.25))
	set_param("overlap_level", "overlap_level", Vector2(0.25, 0.25))
	set_param("smoothing", "smoothing", false)
	set_param("random_seed_enabled", "random_seed_enabled", false)
	set_param("output_tile_size", "output_tile_size", Const.DEFAULT_TILE_SIZE)
	set_param("subtile_offset", "subtile_offset", Vector2.ZERO)
	set_param("export_type", "export_type", Const.EXPORT_TYPE_UKNOWN)
	set_param("export_png_path", "export_png_path", "")
	set_param("export_godot3_resource_path", "export_godot3_resource_path", "")
	set_param("export_godot3_autotile_type", "export_godot3_autotile_type", Const.GODOT3_UNKNOWN_AUTOTILE_TYPE)
	set_param("export_godot3_tile_name", "export_godot3_tile_name", "")
	return true


func block_failed_tile():
	$ErrorOverlay.set_tooltip("Error loading file")
	$ErrorOverlay.show()


func load_texture(path: String) -> bool:
	if path.empty():
		texture_path = path
		loaded_texture = null
		return false
	var file_path: String = current_directory + "/" + path
	var image = Image.new()
	var err: int
	err = image.load(file_path)
	if err != OK:
		State.report_error("Error loading texture at: \"" + _tile_data["texture"] + "\" for tile \"" + tile_file_name + "\"")
		return false
	texture_path = file_path
	loaded_texture = ImageTexture.new()
	loaded_texture.create_from_image(image, 0)
	return true


func load_ruleset(path: String) -> bool:
	if path.empty():
		return false	
	var file_path: String = current_directory + "/" + path
	loaded_ruleset = Ruleset.new(file_path)
	if loaded_ruleset.is_loaded:
		ruleset_path = file_path
	if loaded_ruleset.last_error != -1:
		State.report_error("Error loading ruleset at: \"" + _tile_data["ruleset"] + "\" for tile \"" + tile_file_name + "\"")
		State.report_error("\nError in ruleset %s :\n" % file_path + loaded_ruleset.last_error_message)
		return false
	return true


func load_template(path: String) -> bool:
	if path.empty():
		return false	
	var file_path: String = current_directory + "/" + path
	var image = Image.new()
	var err: int
	err = image.load(file_path)
	if err != OK:
		State.report_error("Error loading template at: \"" + _tile_data["template"] + "\" for tile \"" + tile_file_name + "\"")
		return false
	if image.get_size().x < Const.TEMPLATE_TILE_SIZE or image.get_size().y < Const.TEMPLATE_TILE_SIZE:
		State.report_error("Error in template: template texture size should be at least 32x32px")
		return false
	template_path = file_path
	loaded_template = ImageTexture.new()
	loaded_template.create_from_image(image, 0)
	parse_template()
	return true


func parse_template():
	result_subtiles_by_bitmask.clear()
	if loaded_template == null:
		return
	template_size = loaded_template.get_size() / Const.TEMPLATE_TILE_SIZE
	for x in range(template_size.x):
		for y in range(template_size.y):
			var mask: int = get_template_mask_value(loaded_template.get_data(), x, y)
			var has_tile: bool = get_template_has_tile(loaded_template.get_data(), x, y)
			if has_tile:
				if not result_subtiles_by_bitmask.has(mask):
					result_subtiles_by_bitmask[mask] = []
				result_subtiles_by_bitmask[mask].append(GeneratedSubTile.new(mask, Vector2(x, y)))


func get_template_mask_value(template_image: Image, x: int, y: int) -> int:
	var mask_check_points: Dictionary = Const.TEMPLATE_MASK_CHECK_POINTS
	var mask_value: int = 0
	template_image.lock()
	for mask in mask_check_points:
		var pixel_x: int = x * Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].x
		var pixel_y: int = y * Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].y
		if not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white):
			mask_value += mask
	template_image.unlock()
	return mask_value


func get_template_has_tile(template_image: Image, x: int, y: int) -> bool:
	template_image.lock()
	var pixel_x: int = x * Const.TEMPLATE_TILE_SIZE + int(Const.MASK_CHECK_CENTER.x)
	var pixel_y: int = y * Const.TEMPLATE_TILE_SIZE + int(Const.MASK_CHECK_CENTER.y)
	var has_tile: bool = not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white)
	template_image.unlock()
	return has_tile


func create_tree_items():
	tile_row = tree.create_item()
	tile_row.set_text(0, tile_file_name)
	add_ruleset_item(_tile_data["ruleset"])
	add_template_item(_tile_data["template"])


func add_ruleset_item(file_name: String):
	ruleset_row = tree.create_item(tile_row)
	ruleset_row.set_text(0, RULESET_PREFIX + file_name)


func add_template_item(file_name: String):
	template_row = tree.create_item(tile_row)
	template_row.set_text(0, TEMPLATE_PREFIX + file_name)


func _on_Tree_item_selected():
	var selected_row: TreeItem = tree.get_selected()
#	if selected_row == tree.get_root():
#		tree.get_root().collapsed = false
	emit_signal("row_selected", selected_row)
	set_selected(true)


func select_root():
	tree.get_root().select(0)


func select_row(row: TreeItem):
	row.select(0)


func set_selected(selected: bool):
	if selected:
		highlight_rect.show()
		is_selected = true
	else:
		highlight_rect.hide()
		is_selected = false


func deselect_except(row: TreeItem):
	var selected_row: TreeItem = tree.get_selected()
	if is_instance_valid(selected_row) and row != selected_row:
		selected_row.deselect(0)
		set_selected(false)


func _on_Tree_item_collapsed(item: TreeItem):
	if item.collapsed:
		rect_min_size.y = HEIGHT_COLLAPSED
	else:
		rect_min_size.y = HEIGHT_EXPANDED


func update_texture(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	texture_path = abs_path
	if not load_texture(rel_path):
		loaded_texture = null
		if not abs_path.empty():
			State.report_error("Error: invalid texture path")
	_tile_data["texture"] = rel_path
	return true


func update_ruleset(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	ruleset_path = abs_path
	if not load_ruleset(rel_path):
		loaded_ruleset = null
		if not abs_path.empty():
			State.report_error("Error: invalid ruleset")
	ruleset_row.set_text(0, RULESET_PREFIX + rel_path)
	_tile_data["ruleset"] = rel_path
	return true


func update_template(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	template_path = abs_path
	if not load_template(rel_path):
		loaded_template = null
		if not abs_path.empty():
			State.report_error("Error: invalid template")
	template_row.set_text(0, TEMPLATE_PREFIX + rel_path)
	_tile_data["template"] = rel_path
	return true


func update_input_tile_size(new_size: Vector2) -> bool:
	if new_size != input_tile_size and (new_size.x > 0 and new_size.y > 0):
		input_tile_size = new_size
		_tile_data["input_tile_size"] = {
			"x": input_tile_size.x,
			"y": input_tile_size.y
		}
	return true


func update_merge_level(new_merge_level: Vector2) -> bool:
	merge_level = new_merge_level
	_tile_data["merge_level"] = {
		"x": new_merge_level.x,
		"y": new_merge_level.y
	}
	return true


func update_overlap_level(new_overlap_level: Vector2) -> bool:
	overlap_level = new_overlap_level
	_tile_data["overlap_level"] = {
		"x": overlap_level.x,
		"y": overlap_level.y
	}
	return true


func update_smoothing(new_smoothig: bool) -> bool:
	smoothing = new_smoothig
	_tile_data["smoothing"] = smoothing
	return true


func update_random_seed_enabled(new_random_seed_enabled: bool) -> bool:
	random_seed_enabled = new_random_seed_enabled
	_tile_data["random_seed_enabled"] = random_seed_enabled
	return true


func update_random_seed_value(new_seed: int) -> bool:
	random_seed_value = new_seed
	_tile_data["random_seed_value"] = random_seed_value
	return true


func update_output_tile_size(size_key: int) -> bool:
	if size_key == Const.NO_SCALING :
		output_tile_size = input_tile_size
	else:
		var size_x: int = Const.OUTPUT_TILE_SIZE_OPTIONS.keys()[size_key]
		output_tile_size = Vector2(size_x, size_x)
		_tile_data["output_tile_size"] = {
			"x": size_x,
			"y": size_x,
		}
	return true


func update_subtile_offset(new_offset: Vector2) -> bool:
	subtile_offset = new_offset
	_tile_data["subtile_offset"] = {
		"x": subtile_offset.x,
		"y": subtile_offset.y
	}
#	_tile_data["subtile_offset"] = subtile_offset
	return true


func update_export_png_path(new_path: String) -> bool:
	export_png_path = new_path
	_tile_data["export_png_path"] = export_png_path
	return true


func update_export_godot3_resource_path(new_path: String) -> bool:
	export_godot3_resource_path = new_path
	_tile_data["export_godot3_resource_path"] = export_godot3_resource_path
	return true


func update_export_godot3_autotile_type(new_type: int) -> bool:
	export_godot3_autotile_type = new_type
	_tile_data["export_godot3_autotile_type"] = export_godot3_autotile_type
	return true


func update_export_godot3_tile_name(new_name: String) -> bool:
	export_godot3_tile_name = new_name
	_tile_data["export_godot3_tile_name"] = export_godot3_tile_name
	return true


func update_export_type(new_type: int) -> bool:
	export_type = new_type
	_tile_data["export_type"] = export_type
	return true


func update_param(param_key: int, value) -> bool:
	match param_key:
		PARAM_TEXTURE:
			return update_texture(value)
		PARAM_RULESET:
			return update_ruleset(value)
		PARAM_TEMPLATE:
			return update_template(value)
		PARAM_INPUT_SIZE:
			return update_input_tile_size(value)
		PARAM_MERGE:
			return update_merge_level(value)
		PARAM_OVERLAP:
			return update_overlap_level(value)
		PARAM_SMOOTHING:
			return update_smoothing(value)
		PARAM_RANDOM_SEED_ENABLED:
			return update_random_seed_enabled(value)
		PARAM_RANDOM_SEED_VALUE:
			return update_random_seed_value(value)
		PARAM_OUTPUT_SIZE:
			return update_output_tile_size(value)
		PARAM_SUBTILE_OFFSET:
			return update_subtile_offset(value)
		PARAM_EXPORT_TYPE:
			return update_export_type(value)
		PARAM_EXPORT_PNG_PATH:
			return update_export_png_path(value)
		PARAM_EXPORT_GODOT3_RESOURCE_PATH:
			return update_export_godot3_resource_path(value)
		PARAM_EXPORT_GODOT3_AUTTOTILE_TYPE:
			return update_export_godot3_autotile_type(value)
		PARAM_EXPORT_GODOT3_TILE_NAME:
			return update_export_godot3_tile_name(value)
	return false


func save():
#	print("tile %s saved" % tile_file_name)
	var path := current_directory + "/" + tile_file_name
	var file := File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(_tile_data, "\t"))
	file.close()
