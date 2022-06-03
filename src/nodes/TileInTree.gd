extends Control

class_name TileInTree

signal row_selected(row)
#signal report_error(text)

const HEIGHT_EXPANDED := 120
const HEIGHT_COLLAPSED := 50
const RULESET_PREFIX := "Ruleset: "
const TEXTURE_PREFIX := "Texture: "
const TEMPLATE_PREFIX := "Template: "

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
var merge_level := Vector2(0.25, 0.25)
var overlap_level:= Vector2(0.25, 0.25)
var smoothing := false

var tile_row: TreeItem
var ruleset_row: TreeItem
var template_row: TreeItem

onready var tree: Tree = $Tree
onready var highlight_rect := $ColorRect


func _ready():
	if is_loaded:
		create_tree_items()
		rect_min_size.y = HEIGHT_EXPANDED


func load_tile(directory: String, tile_file: String) -> bool:
	current_directory = directory
	tile_file_name = tile_file
	var path := directory + "/" + tile_file
	var file := File.new()
	file.open(path, File.READ)
	var file_text := file.get_as_text()
	file.close()
	var parsed_data = parse_json(file_text)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		State.report_error("Error loading tile: " + tile_file)
		block_failed_tile()
		return false
	_tile_data = parsed_data
	is_loaded = true
	input_tile_size = Vector2(_tile_data["input_tile_size"]["x"], _tile_data["input_tile_size"]["y"])
	if not load_texture(_tile_data["texture"]) or \
			not load_ruleset(_tile_data["ruleset"]) or \
			not load_template(_tile_data["template"]):
		block_failed_tile()
		return false
	merge_level = Vector2(_tile_data["merge_level"], _tile_data["merge_level"])
	overlap_level = Vector2(_tile_data["overlap_level"], _tile_data["overlap_level"])
	return true


func block_failed_tile():
	$ErrorOverlay.set_tooltip("Error loading file")
	$ErrorOverlay.show()


func load_texture(path: String) -> bool:
	var file_path: String = current_directory + path
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


func set_texture(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	if not load_texture(rel_path):
		return false
	_tile_data["texture"] = rel_path
	return true


func set_ruleset(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	if not load_ruleset(rel_path):
		return false
	ruleset_row.set_text(0, RULESET_PREFIX + rel_path)
	_tile_data["ruleset"] = rel_path
	return true


func set_template(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir + "/")
	if not load_template(rel_path):
		return false
	template_row.set_text(0, TEMPLATE_PREFIX + rel_path)
	_tile_data["template"] = rel_path
	return true


func set_input_tile_size(new_size: Vector2):
	if input_tile_size.x > 0 and input_tile_size.y > 0:
		input_tile_size = new_size
		_tile_data["input_tile_size"] = {
			"x": input_tile_size.x,
			"y": input_tile_size.y
		}


func set_merge_level(new_merge_level: Vector2):
	merge_level = new_merge_level
	_tile_data["merge_level"] = merge_level.x


func set_overlap_level(new_overlap_level: Vector2):
	overlap_level = new_overlap_level
	_tile_data["overlap_level"] = overlap_level.x


func save():
#	print("tile %s saved" % tile_file_name)
	var path := current_directory + "/" + tile_file_name
	var file := File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(_tile_data, "\t"))
	file.close()
