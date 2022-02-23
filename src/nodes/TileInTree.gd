extends Control

class_name TileInTree

signal row_selected(row)
signal report_error(text)

const HEIGHT_EXPANDED := 144
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
var result_tiles_by_bitmask: Dictionary

var texture_path: String
var template_path: String
var ruleset_path: String
var input_tile_size: Vector2
var output_tile_size: Vector2 = Vector2(64,64)
var merge_level := Vector2(0.25, 0.25)
var overlap_level:= Vector2(0.25, 0.25)
var smoothing := false

var tile_row: TreeItem
var texture_row: TreeItem
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
	if typeof(parsed_data) == TYPE_DICTIONARY:
		_tile_data = parsed_data
		is_loaded = true
		input_tile_size = Vector2(_tile_data["input_tile_size"]["x"], _tile_data["input_tile_size"]["y"])
		load_texture(_tile_data["texture"])
		load_ruleset(_tile_data["ruleset"])
		load_template(_tile_data["template"])
		return true
	emit_signal("report_error", "Error loading tile: " + tile_file)
	return false
	

func load_texture(path: String) -> bool:
	var file_path: String = current_directory + "/" + path
	var image = Image.new()
	var err: int
	err = image.load(file_path)
	if err == OK:
		texture_path = file_path
		loaded_texture = ImageTexture.new()
		loaded_texture.create_from_image(image, 0)
		return true
	return false


func load_ruleset(path: String) -> bool:
	var file_path: String = current_directory + "/" + path
	loaded_ruleset = Ruleset.new(file_path)
	if loaded_ruleset.is_loaded:
		ruleset_path = file_path
	if loaded_ruleset.last_error != -1:
		print("In ruleset %s :\n" % file_path + loaded_ruleset.last_error_message)
#		emit_signal("report_error", loaded_ruleset.last_error_message)
		return false
	return true


func load_template(path: String) -> bool:
	var file_path: String = current_directory + "/" + path
	var image = Image.new()
	var err: int
	err = image.load(file_path)
	if err == OK:
		if image.get_size().x < Const.TEMPLATE_TILE_SIZE or image.get_size().y < Const.TEMPLATE_TILE_SIZE:
#			print("Template texture size should be at least 32x32px")
			return false
		template_path = file_path
		loaded_template = ImageTexture.new()
		loaded_template.create_from_image(image, 0)
		parse_template()
		return true
	return false


func parse_template():
	result_tiles_by_bitmask.clear()
	if loaded_template == null:
		return
	var template_size := loaded_template.get_size() / Const.TEMPLATE_TILE_SIZE
	for x in range(template_size.x):
		for y in range(template_size.y):
			var mask: int = get_template_mask_value(loaded_template.get_data(), x, y)
			var has_tile: bool = get_template_has_tile(loaded_template.get_data(), x, y)
			if has_tile:
				if not result_tiles_by_bitmask.has(mask):
					result_tiles_by_bitmask[mask] = []
				result_tiles_by_bitmask[mask].append(GeneratedTile.new(mask, Vector2(x, y)))


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
	add_texture_item(_tile_data["texture"])
	add_ruleset_item(_tile_data["ruleset"])
	add_template_item(_tile_data["template"])


func add_texture_item(file_name: String):
	texture_row = tree.create_item(tile_row)
	texture_row.set_text(0, TEXTURE_PREFIX + file_name)


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


func set_texture(abs_path: String):
	var rel_path := abs_path.trim_prefix(Const.current_dir + "/")
	load_texture(rel_path)
	texture_row.set_text(0, TEXTURE_PREFIX + rel_path)


func set_ruleset(abs_path: String):
	var rel_path := abs_path.trim_prefix(Const.current_dir + "/")
	load_ruleset(rel_path)
	ruleset_row.set_text(0, RULESET_PREFIX + rel_path)


func set_template(abs_path: String):
	var rel_path := abs_path.trim_prefix(Const.current_dir + "/")
	load_template(rel_path)
	template_row.set_text(0, TEMPLATE_PREFIX + rel_path)


func set_input_tile_size(new_size: Vector2):
	if input_tile_size.x > 0 and input_tile_size.y > 0:
		input_tile_size = new_size


func set_merge_level(new_merge_level: Vector2):
	merge_level = new_merge_level


func set_overlap_level(new_overlap_level: Vector2):
	overlap_level = new_overlap_level


func save():
	pass
