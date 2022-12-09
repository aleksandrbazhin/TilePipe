class_name TPTile
extends Control


signal row_selected(row)
signal copy_tile_called(tile)
signal rename_tile_called(tile)
signal delete_tile_called(tile)


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
	PARAM_OUTPUT_RESIZE,
	PARAM_OUTPUT_SIZE,
	PARAM_SUBTILE_SPACING,
	PARAM_EXPORT_TYPE,
	PARAM_EXPORT_PNG_PATH,
	PARAM_EXPORT_MULTIPLE_PNG_PATH,
	PARAM_EXPORT_GODOT3_RESOURCE_PATH,
	PARAM_EXPORT_GODOT3_AUTTOTILE_TYPE,
	PARAM_EXPORT_GODOT3_TILE_NAME,
	PARAM_FRAME_NUMBER,
	PARAM_FRAME_RANDOM_PRIORITIES,
	PARAM_UI_RESULT_DISPLAY_SCALE,
	PARAM_UI_TREE_COLLAPSED,
}

const HEIGHT_EXPANDED := 120
const HEIGHT_COLLAPSED := 50
const RULESET_PREFIX :=  "[Ruleset] "
const TEMPLATE_PREFIX := "[Template] "
const EMPTY_TILE_CONTENT := {"texture": "", "ruleset": "", "template": ""}

var is_loaded := false
var is_texture_loaded := false
var is_ruleset_loaded := false
var is_template_loaded := false

var _tile_data: Dictionary
var current_directory: String
var tile_file_name: String
var is_selected := false
var input_texture: Texture
var ruleset: Ruleset
var template: Texture
var frames := [] # Array of TPTileFrame

var template_size: Vector2
var texture_path: String
var template_path: String
var ruleset_path: String
var texture_modified_time: int
var template_modified_time: int
var ruleset_modified_time: int

var input_tile_size: Vector2
# input_parts[part_index] = [variant1: TilePart, variant2: TilePart, ...]
var input_parts: Dictionary 
var output_resize: bool
var output_tile_size: Vector2 = Vector2(64,64)
var subtile_spacing := Vector2.ZERO
var merge_level := Vector2(0.25, 0.25)
var overlap_level:= Vector2(0.25, 0.25)
var smoothing := false
var random_seed_enabled := false
var random_seed_value := 0
var frame_number := 1
var ui_result_display_scale: float = 1.0
var ui_tree_collapsed: bool = true

var export_type: int = Const.EXPORT_TYPE_UKNOWN
var export_png_path: String
var export_multiple_png_path: String
var export_godot3_resource_path: String
var export_godot3_autotile_type: int = Const.GODOT3_UNKNOWN_AUTOTILE_TYPE
var export_godot3_tile_name: String

var tile_row: TreeItem
var ruleset_row: TreeItem
var template_row: TreeItem
#var output_texture: Texture

onready var tree: Tree = $Tree
onready var highlight_rect := $ColorRect


func _ready():
	if is_loaded:
		create_tree_items()
		tile_row.collapsed = ui_tree_collapsed
		if ui_tree_collapsed:
			rect_min_size.y = HEIGHT_COLLAPSED
		else:
			rect_min_size.y = HEIGHT_EXPANDED


# the purpose of this is to be able to add new parameters to .tptile in the future
# this way the program will still work, and will update the .tptile with defaults
func set_tile_param(param_name: String, settings_param_name: String, default_value):
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
			TYPE_REAL:
				set(param_name, float(_tile_data[settings_param_name]))
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
		init_frames()
	else:
		var path := directory + tile_file
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
# warning-ignore:unused_variable
	is_texture_loaded = load_texture(_tile_data["texture"])
# warning-ignore:unused_variable
	is_ruleset_loaded = load_ruleset(_tile_data["ruleset"])
# warning-ignore:unused_variable
	set_tile_param("frame_number", "frame_number", 1)
	is_template_loaded = load_template(_tile_data["template"])
	set_tile_param("input_tile_size", "input_tile_size", Const.DEFAULT_TILE_SIZE)
	set_tile_param("merge_level", "merge_level", Vector2(0.25, 0.25))
	set_tile_param("overlap_level", "overlap_level", Vector2(0.25, 0.25))
	set_tile_param("smoothing", "smoothing", false)
	set_tile_param("random_seed_enabled", "random_seed_enabled", false)
	set_tile_param("output_resize", "output_resize", false)
	set_tile_param("output_tile_size", "output_tile_size", input_tile_size)
	set_tile_param("subtile_spacing", "subtile_spacing", Vector2.ZERO)
	set_tile_param("export_type", "export_type", Const.EXPORT_TYPE_UKNOWN)
	set_tile_param("export_png_path", "export_png_path", "")
	set_tile_param("export_multiple_png_path", "export_multiple_png_path", "")
	set_tile_param("export_godot3_resource_path", "export_godot3_resource_path", "")
	set_tile_param("export_godot3_autotile_type", "export_godot3_autotile_type", Const.GODOT3_UNKNOWN_AUTOTILE_TYPE)
	set_tile_param("export_godot3_tile_name", "export_godot3_tile_name", "")
	set_tile_param("ui_result_display_scale", "ui_result_display_scale", 1.0)
	set_tile_param("ui_tree_collapsed", "ui_tree_collapsed", true)
	
	if is_texture_loaded and is_ruleset_loaded:
		split_input_into_tile_parts()
	set_frame_randomness()
	return true


func get_part_frame_variant_priority(frame_index: int, part_index: int, 
		variant_index: int) -> int:
	if frame_index >= frames.size():
		return 1
	var frame: TPTileFrame = frames[frame_index]
	return frame.get_part_priority(part_index, variant_index)


func set_frame_randomness():
	if not "frame_randomness_data" in _tile_data:
		return
	var priorities: Dictionary = _tile_data["frame_randomness_data"]
	for frame_index in priorities:
		if int(frame_index) >= frames.size():
			return
		var frame: TPTileFrame = frames[int(frame_index)]
		var frame_priorities: Dictionary = priorities[frame_index]
		for part_index in frame_priorities:
			if int(part_index) >= input_parts.size():
				break
			var variants: Array = input_parts[int(part_index)]
			var part_priorities: Dictionary = frame_priorities[part_index]
			for variant_index in part_priorities:
				if int(variant_index) >= variants.size():
					break
				frame.set_part_priority(int(part_index), int(variant_index), part_priorities[variant_index])


func split_input_into_tile_parts() -> bool:
	if ruleset == null or input_texture == null:
		return false
	input_parts = {}
	var input_image: Image = input_texture.get_data()
#	var min_input_tiles := ruleset.parts.size()
	for part_index in ruleset.parts.size():
		input_parts[part_index] = []
		var variant_index := 0
		while variant_index * input_tile_size.y <= input_image.get_size().y or input_parts[part_index].size() == 0 :
			var part := TilePart.new()
			part.create(int(input_tile_size.x), int(input_tile_size.y), false, Image.FORMAT_RGBA8)
			var copy_rect := Rect2(part_index * input_tile_size.x, variant_index * input_tile_size.y, 
				input_tile_size.x, input_tile_size.y)
			part.blit_rect(input_image, copy_rect, Vector2.ZERO)
			if not part.is_invisible() or input_parts[part_index].size() == 0:
				input_parts[part_index].append(part)
				part.part_index = part_index
				part.variant_index = variant_index
				part.ruleset_part_index = ruleset.parts[part_index]
			variant_index += 1
#			for frame in frames:
#				pass 
	return true


func check_texture_changed() -> bool:
	var f := File.new()
	return texture_modified_time < f.get_modified_time(texture_path)


func check_template_changed() -> bool:
	var f := File.new()
	return template_modified_time < f.get_modified_time(template_path)


func check_ruleset_changed() -> bool:
	var f := File.new()
	return ruleset_modified_time < f.get_modified_time(ruleset_path)


func smart_reload_assets():
	if check_texture_changed() or check_template_changed() or check_ruleset_changed():
		load_texture(texture_path.trim_prefix(State.current_dir))
		load_ruleset(ruleset_path.trim_prefix(State.current_dir))
		init_frames()
		load_template(template_path.trim_prefix(State.current_dir))
		split_input_into_tile_parts()
		set_frame_randomness()
		State.emit_signal("tile_needs_render")


func reload():
	load_tile(current_directory, tile_file_name)
	State.emit_signal("tile_needs_render")


func block_failed_tile():
	$ErrorOverlay.set_tooltip("Error loading file")
	$ErrorOverlay.show()


func load_texture(path: String) -> bool:
	if path.empty():
		texture_path = path
		input_texture = null
		return false
	var file_path: String = current_directory + path
	var image = Image.new()	
	var err: int = image.load(file_path)
	if err != OK:
		State.report_error("Error loading texture at: \"" + _tile_data["texture"] + "\" for tile \"" + tile_file_name + "\"")
		return false
	texture_path = file_path
	input_texture = ImageTexture.new()
	input_texture.create_from_image(image, 0)
	var f := File.new()
	texture_modified_time = f.get_modified_time(file_path)
	return true


func load_ruleset(path: String) -> bool:
	if path.empty():
		return false	
	var file_path: String = current_directory + path
	ruleset = Ruleset.new(file_path)
	ruleset_path = file_path
	if ruleset.last_error != -1:
		State.report_error("\nError in ruleset %s :\n" % file_path + ruleset.last_error_message)
		return false
	var f := File.new()
	ruleset_modified_time = f.get_modified_time(file_path)
	return true


func load_template(path: String) -> bool:
	init_frames()
	if path.empty():
		return false
	var file_path: String = current_directory + path
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
	template = ImageTexture.new()
	template.create_from_image(image, 0)
	parse_template()
	var f := File.new()
	template_modified_time = f.get_modified_time(file_path)	
	return true


# return template size in tiles 
func get_template_size() -> Vector2:
	return template.get_size() / Const.TEMPLATE_TILE_SIZE


func init_frames():
	frames.clear()
	for frame_index in frame_number:
		var frame := TPTileFrame.new(frame_index)
		frames.append(frame)

# IMPORTANT! always call init_frames before it
# creates in each frame index of bitmasks and corresponding generated subtiles
func parse_template():
	if template == null:
		return
	template_size = get_template_size()
	var template_image: Image = template.get_data()
	var mask_check_points: Dictionary = Const.TEMPLATE_MASK_CHECK_POINTS
	var mask_value: int = 0
	template_image.lock()
	for x in range(template_size.x):
		for y in range(template_size.y):
			if get_template_has_tile(template_image, x, y):
				var mask: int = get_template_mask_value(template_image, x, y)
				for frame in frames:
					frame.append_subtile(mask, Vector2(x, y))
	template_image.unlock()


func get_template_mask_value(template_image: Image, x: int, y: int) -> int:
	var mask_check_points: Dictionary = Const.TEMPLATE_MASK_CHECK_POINTS
	var mask_value: int = 0
	for mask in mask_check_points:
		var pixel_x: int = x * Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].x
		var pixel_y: int = y * Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].y
		if not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white):
			mask_value += mask
	return mask_value


func get_template_has_tile(template_image: Image, x: int, y: int) -> bool:
	var pixel_x: int = x * Const.TEMPLATE_TILE_SIZE + int(Const.MASK_CHECK_CENTER.x)
	var pixel_y: int = y * Const.TEMPLATE_TILE_SIZE + int(Const.MASK_CHECK_CENTER.y)
	var has_tile: bool = not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white)
	return has_tile


func create_tree_items():
	tile_row = tree.create_item()
	tile_row.set_text(0, tile_file_name)
	add_ruleset_item(_tile_data["ruleset"].get_file())
	add_template_item(_tile_data["template"].get_file())


func add_ruleset_item(file_name: String):
	ruleset_row = tree.create_item(tile_row)
	ruleset_row.set_text(0, RULESET_PREFIX + file_name)


func add_template_item(file_name: String):
	template_row = tree.create_item(tile_row)
	template_row.set_text(0, TEMPLATE_PREFIX + file_name)


func _on_Tree_item_selected():
	var selected_row: TreeItem = tree.get_selected()
	if selected_row == tree.get_root():
		$Controls.color = Color("444e62")
	else:
		$Controls.color = Color("282d33")
	smart_reload_assets()
	emit_signal("row_selected", selected_row)
	set_selected(true)
	$Controls.show()


func select_root():
	tree.get_root().select(0)


func select_row(row: TreeItem):
	row.select(0)


func set_selected(selected: bool):
	if selected:
		highlight_rect.show()
		is_selected = true
		$Controls.show()
	else:
		highlight_rect.hide()
		is_selected = false
		$Controls.hide()


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
	update_param(PARAM_UI_TREE_COLLAPSED, item.collapsed)
	save()


func update_texture(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir)
	texture_path = abs_path
	if not load_texture(rel_path):
		input_texture = null
		clear_render_result()
		if not abs_path.empty():
			State.report_error("Error: invalid texture path")
	_tile_data["texture"] = rel_path
	assure_tile_size()
	split_input_into_tile_parts()
	return true


func update_ruleset(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir)
	ruleset_path = abs_path
	if not load_ruleset(rel_path):
		ruleset = null
		clear_render_result()
		if not abs_path.empty():
			State.report_error("Error: invalid ruleset")
	ruleset_row.set_text(0, RULESET_PREFIX + rel_path)
	_tile_data["ruleset"] = rel_path
	split_input_into_tile_parts()
	return true


func update_template(abs_path: String) -> bool:
	var rel_path := abs_path.trim_prefix(State.current_dir)
	template_path = abs_path
	if not load_template(rel_path):
		template = null
		clear_render_result()
		if not abs_path.empty():
			State.report_error("Error: invalid template")
	template_row.set_text(0, TEMPLATE_PREFIX + rel_path)
	_tile_data["template"] = rel_path
	split_input_into_tile_parts()
	return true


func has_loaded_output_tile_size() -> bool:
	return _tile_data.has("output_tile_size")


func assure_tile_size():
	if !_tile_data.has("input_tile_size"):
		if input_texture == null:
			input_tile_size = Const.DEFAULT_TILE_SIZE
		else:
			var size = Vector2(input_texture.get_size().y, input_texture.get_size().y)
			update_input_tile_size(size)
			output_tile_size = get_output_tile_size()


func update_input_tile_size(new_size: Vector2) -> bool:
	if new_size != input_tile_size and (new_size.x > 0 and new_size.y > 0):
		input_tile_size = new_size
		_tile_data["input_tile_size"] = {
			"x": input_tile_size.x,
			"y": input_tile_size.y
		}
		split_input_into_tile_parts()
	return true


func update_output_resize(value: bool) -> bool:
	output_resize = value
	_tile_data["output_resize"] = value
	return true


func update_output_tile_size(new_size: Vector2) -> bool:
	if new_size.x > 0 and new_size.y > 0:
		output_tile_size = new_size
		_tile_data["output_tile_size"] = {
			"x": new_size.x,
			"y": new_size.y,
		}
	return true


func update_tree_icon():
	var tree_icon: TileInTreeIcon = $TileInTreeIcon
	tree_icon.icon_texture = get_first_frame_texture()
	tree_icon.output_tile_size = get_output_tile_size()
	tree_icon.update()


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


func update_subtile_spacing(new_spacing: Vector2) -> bool:
	subtile_spacing = new_spacing
	_tile_data["subtile_spacing"] = {
		"x": subtile_spacing.x,
		"y": subtile_spacing.y
	}
	return true


func update_export_png_path(new_path: String) -> bool:
	export_png_path = new_path
	_tile_data["export_png_path"] = export_png_path
	return true


func update_export_multiple_png_path(new_path: String) -> bool:
	export_multiple_png_path = new_path
	_tile_data["export_multiple_png_path"] = export_multiple_png_path
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


func update_frame_number(new_frame_number: int) -> bool:
	frame_number = new_frame_number
	init_frames()
	parse_template()
	set_frame_randomness()
	_tile_data["frame_number"] = frame_number
	return true


func update_frame_random_priorities(frame_part_variant_priority: Array) -> bool:
	var frame_index: int = frame_part_variant_priority[0]
	var part_index: int = frame_part_variant_priority[1]
	var variant_index: int = frame_part_variant_priority[2]
	var priority: int = frame_part_variant_priority[3]
	if frame_index >= frames.size():
		return false
	if part_index >= input_parts.size():
		return false
	frames[frame_index].set_part_priority(part_index, variant_index, priority)
	var frame_randomness := {}
	for frame_idx in frames.size():
		frame_randomness[frame_idx] = frames[frame_idx].part_random_priorities
	_tile_data["frame_randomness_data"] = frame_randomness
	return true


func update_ui_result_display_scale(value: float) -> bool:
	ui_result_display_scale = value
	_tile_data["ui_result_display_scale"] = ui_result_display_scale
	return true


func update_ui_tree_collapsed(value: bool):
	ui_tree_collapsed = value
	_tile_data["ui_tree_collapsed"] = ui_tree_collapsed
	return true


# returns true if param was successfully changed
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
		PARAM_OUTPUT_RESIZE:
			return update_output_resize(value)
		PARAM_OUTPUT_SIZE:
			return update_output_tile_size(value)
		PARAM_SUBTILE_SPACING:
			return update_subtile_spacing(value)
		PARAM_EXPORT_TYPE:
			return update_export_type(value)
		PARAM_EXPORT_PNG_PATH:
			return update_export_png_path(value)
		PARAM_EXPORT_MULTIPLE_PNG_PATH:
			return update_export_multiple_png_path(value)
		PARAM_EXPORT_GODOT3_RESOURCE_PATH:
			return update_export_godot3_resource_path(value)
		PARAM_EXPORT_GODOT3_AUTTOTILE_TYPE:
			return update_export_godot3_autotile_type(value)
		PARAM_EXPORT_GODOT3_TILE_NAME:
			return update_export_godot3_tile_name(value)
		PARAM_FRAME_NUMBER:
			return update_frame_number(value)
		PARAM_FRAME_RANDOM_PRIORITIES:
			return update_frame_random_priorities(value)
		PARAM_UI_RESULT_DISPLAY_SCALE:
			return update_ui_result_display_scale(value)
		PARAM_UI_TREE_COLLAPSED:
			return update_ui_tree_collapsed(value)
	return false


func save():
	var path := current_directory + tile_file_name
	var file := File.new()
	file.open(path, File.WRITE)
	file.store_string(JSON.print(_tile_data, "\t"))
	file.close()


func get_output_tile_size() -> Vector2:
	if output_resize:
		return output_tile_size
	else:
		return input_tile_size


func glue_frames_into_image() -> Image:
	var result_image := Image.new()
	if frames[0].result_texture == null or frames[0].result_texture.get_data() == null:
		State.report_error("Error: No generated texture in frames, tile not fully defined")
		return null
	var frame_size: Vector2 = frames[0].result_texture.get_size()
	result_image.create(int(frame_size.x), int(frame_size.y) * frames.size(), false, Image.FORMAT_RGBA8)
	for frame in frames:
		var frame_image: Image = frame.result_texture.get_data()
		result_image.blit_rect(frame_image, 
			Rect2(Vector2.ZERO, frame_image.get_size()), 
			Vector2(0, frame_size.y * frame.index))
	return result_image 


func get_first_frame_texture() -> Texture:
	if frames.size() == 0:
		return null
	if frames[0].result_texture == null:
		return null
	return frames[0].result_texture


func get_tile_icon() -> Image:
	if get_first_frame_texture() == null:
		return null
	if frames[0].result_subtiles_by_bitmask.size() == 0:
		return null
	var first_subtile_key = frames[0].result_subtiles_by_bitmask.keys()[0]
	if frames[0].result_subtiles_by_bitmask[first_subtile_key].size() == 0:
		return null
	var first_subtile: GeneratedSubTile = frames[0].result_subtiles_by_bitmask[first_subtile_key][0]
	return first_subtile.image


func _on_CopyButton_pressed():
	emit_signal("copy_tile_called", self)


func _on_DelButton_pressed():
	emit_signal("delete_tile_called", self)


func _on_RenameButton_pressed():
	emit_signal("rename_tile_called", self)


func rename(new_name: String):
	tile_file_name = new_name
	tile_row.set_text(0, tile_file_name)
	

func clear_render_result():
	for frame in frames:
		frame.clear()
