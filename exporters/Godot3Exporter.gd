extends PopupDialog

class_name GodotExporter

signal settings_saved()

const DEFAULT_TILES_LABEL: String = "Select tileset to edit tiles ↑"

var resource_path: String = ""
var texture_path: String = "" # os path for current texture to save, not relative like res://
var tile_name: String = ""
# we need it to indentify tiles since it depends on input filename
var last_generated_tile_name: String = ""
var autotile_type: int = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3
# data passed from main window
var current_texture_image := Image.new()
var current_tile_size: Vector2
var current_tile_masks: Dictionary
var current_texture_size: Vector2
var current_tile_spacing: int
var current_smoothing: bool = false

# {template_position (Vector2): id (int)}
var collision_shapes_to_id: Dictionary
var is_tile_match: bool = false
var is_match_error_found: bool = false
var scroll_deferred: bool = false

onready var resource_name_edit: LineEdit = $VBox/HBoxTileset/ResourceNameEdit
onready var tile_name_edit: LineEdit = $VBox/TilesPanelContainer/VBox/HBoxNewTile/LineEditName
onready var tile_texture_edit: LineEdit = $VBox/TilesPanelContainer/VBox/HBoxNewTile/LineEditTexture
onready var autotile_type_select: OptionButton = $VBox/TilesPanelContainer/VBox/HBoxNewTile/OptionButton
onready var new_tile_container: HBoxContainer = $VBox/TilesPanelContainer/VBox/HBoxNewTile
onready var tiles_header: Label = $VBox/TilesLabel
onready var resource_dialog: FileDialog = $ResourceFileDialog
onready var texture_dialog: FileDialog = $TextureFileDialog
onready var error_dialog: AcceptDialog = $ErrorDialog
onready var blocking_rect: ColorRect = $ColorRect
onready var blocking_rect_tiles: ColorRect = $TileBlockColorRect
onready var existing_tiles_container: VBoxContainer = $VBox/TilesPanelContainer/VBox/ScrollContainer/VBoxExistiingTiles
onready var save_confirm_dialog: ConfirmationDialog = $SaveConfirmationDialog
onready var overwrite_tileset_select: CheckButton = $VBox/HBoxTileset/OverrideCheckButton
onready var collisions_check: CheckButton = $VBox/TilesPanelContainer/VBox/HBoxNewTile/CollisionsCheckButton
onready var collision_dialog: CollisionGenerator = $CollisionGenerator
onready var temp_tile_row: GodotTileRow = $VBox/TilesPanelContainer/VBox/ScrollContainer/VBoxExistiingTiles/Existing
onready var tiles_scroll_container: ScrollContainer = $VBox/TilesPanelContainer/VBox/ScrollContainer


func _ready():
	resource_dialog.connect("popup_hide", blocking_rect, "hide")
	resource_dialog.connect("about_to_show", blocking_rect, "show")
	texture_dialog.connect("popup_hide", blocking_rect, "hide")
	texture_dialog.connect("about_to_show", blocking_rect, "show")
	error_dialog.connect("popup_hide", blocking_rect, "hide")
	error_dialog.connect("about_to_show", blocking_rect, "show")
	save_confirm_dialog.connect("popup_hide", blocking_rect, "hide")
	save_confirm_dialog.connect("about_to_show", blocking_rect, "show")
	save_confirm_dialog.connect("confirmed", self, "save_all_and_exit")
	collision_dialog.connect("popup_hide", blocking_rect, "hide")
	collision_dialog.connect("about_to_show", blocking_rect, "show")
	collision_dialog.connect("popup_hide", self, "on_collsions_dialog_hide")
	new_tile_container.hide()
	for type in Const.GODOT_AUTOTILE_TYPE:
		var type_id: int = Const.GODOT_AUTOTILE_TYPE[type]
		autotile_type_select.add_item(Const.GODOT_AUTOTILE_TYPE_NAMES[type_id], type_id)


func _process(delta):
	if scroll_deferred:
		tiles_scroll_container.ensure_control_visible(temp_tile_row)
		scroll_deferred = false

func start_export_dialog(
		new_tile_size: Vector2, 
		tiles: Dictionary, 
		new_tile_base_name: String, 
		new_tile_spacing: int, 
		texture_image: Image,
		smoothing: bool = true):
	current_tile_size = new_tile_size
	current_texture_size = texture_image.get_size()
	current_tile_spacing = new_tile_spacing
	current_tile_masks = tiles
	current_texture_image.copy_from(texture_image)
	current_smoothing = smoothing
	autotile_type = Helpers.assume_godot_autotile_type(tiles)
	collisions_check.pressed = false
	collision_dialog.collisions_accepted_by_user = false
	var generated_tile_name: String = new_tile_base_name + Const.TILE_SAVE_SUFFIX
	if last_generated_tile_name.empty() or (last_generated_tile_name != generated_tile_name and tile_name.is_valid_filename()):
		tile_name = generated_tile_name
		texture_path = texture_path_auto_name(texture_path.get_base_dir(), tile_name)
		last_generated_tile_name = generated_tile_name
		save_settings()
	set_lineedit_text(tile_name_edit, tile_name)
	texture_dialog.current_path = texture_path
	set_lineedit_text(tile_texture_edit, texture_path)
	autotile_type_select.selected = autotile_type
	populate_temp_tile_from_inputs()
	if is_a_valid_resource_path(resource_path):
		set_lineedit_text(resource_name_edit, resource_path)
		resource_dialog.current_path = resource_path
		load_tileset(resource_path)
	else:
		if resource_path != Helpers.clear_path(Const.DEFAULT_GODOT_RESOURCE_PATH):
			report_error_inside_dialog("Error: Godot tileset resource path is invalid,\npossibly loading a tilest not belonging to any Godot project")
		set_lineedit_text(resource_name_edit, ".tres")
		resource_dialog.current_path = resource_path
		overwrite_tileset_select.pressed = true
		overwrite_tileset_select.disabled = true
	popup_centered()


func _parse_tileset(tileset_file_content: String, project_path: String) -> Dictionary:
	var parse_result: Dictionary = {
		"textures": {},
		"subresources": {},
		"tiles": [],
		"error": false # error during parsing tileset
	}
	var sections: PoolStringArray = tileset_file_content.split("[resource]", false, 1)
	if sections.size() != 2:
		parse_result["error"] = true
		return parse_result
	var header: String = sections[0]
	var texture_regex := RegEx.new()
	texture_regex.compile('\\[ext_resource path="(.+)" type="Texture" id=(\\d+)\\]')
	var textures: Dictionary = {}
	for texture_result in texture_regex.search_all(header):
		var texture_parsed_path: String = texture_result.strings[1]
		var texture_id: int = int(texture_result.strings[2])
		var texture_absolute_path: String = texture_parsed_path.replace("res://", project_path)
		var texture_relative_path: String = texture_parsed_path.replace("res://", "")
		textures[texture_id] = {
			"relative_path": texture_relative_path,
			"path": texture_absolute_path,
			"image": null,
			"error": false # error when miage does not exist
		}
		if Helpers.file_exists(texture_absolute_path):
			var exisiting_image: Image = Image.new()
			exisiting_image.load(texture_absolute_path)
			textures[texture_id]["image"] = exisiting_image
		else:
			textures[texture_id]["error"] = true
	parse_result["textures"] = textures
	var subresource_regex := RegEx.new()
	subresource_regex.compile('\\s\\[sub_resource type="ConvexPolygonShape2D" id=(\\d+)\\]\\s*' +
							  'points = PoolVector2Array\\(.+\\)\\s')
	for subresource_result in subresource_regex.search_all(header):
		var subresource_id := int(subresource_result.strings[1])
		var subresouces_string: String = subresource_result.strings[0]
		parse_result["subresources"][subresource_id] = subresouces_string
	var tiles_data: String = sections[1]
	var tile_parse_regex := RegEx.new()
	tile_parse_regex.compile('(\\d+)/name\\s*=\\s*"(.+)"\\s*' + 
							'\\d+/texture\\s*=\\s*ExtResource\\(\\s*(\\d+)\\s*\\)\\s*' + 
							'\\d+/tex_offset.*\\s*'+
							'\\d+/modulate.*\\s*'+
							'\\d+/region\\s*=\\s*Rect2\\(([0-9,\\s]+)\\)\\s*' + 
							'\\d+/tile_mode\\s*=\\s*(\\d+)\\s*'+
							'')
	for tile_parse_result in tile_parse_regex.search_all(tiles_data):
		var tile_dict: Dictionary = {
			"id": int(tile_parse_result.strings[1]),
			"name": String(tile_parse_result.strings[2]),
			"texture_id": int(tile_parse_result.strings[3]),
			"tile_mode": int(tile_parse_result.strings[5]),
			"bitmask_mode": -1,
			"icon_rect": Rect2(),
			"shape_ids": []
		}
		if not textures.has(tile_dict["texture_id"]):
			parse_result["error"] = true
		match tile_dict["tile_mode"]:
			TileSet.SINGLE_TILE:
				var rect_string: String = tile_parse_result.strings[4]
				var rect_coords := rect_string.split(",")
				tile_dict["icon_rect"].position = Vector2(int(rect_coords[0]), int(rect_coords[1]))
				tile_dict["icon_rect"].size = Vector2(int(rect_coords[2]), int(rect_coords[3]))
			TileSet.AUTO_TILE, TileSet.ATLAS_TILE:
				var autotile_regex := RegEx.new()
				autotile_regex.compile(
					str(tile_dict["id"]) + '/autotile/icon_coordinate\\s*=\\s*Vector2\\(([0-9,\\s]+)\\)\\s*' +
					str(tile_dict["id"]) + '/autotile/tile_size\\s*=\\s*Vector2\\(([0-9,\\s]+)\\)' )
				var autotile_tile_size: RegExMatch = autotile_regex.search(tiles_data)
				if autotile_tile_size != null:
					var icon_coord_string: String = autotile_tile_size.strings[1]
					var icon_coords := icon_coord_string.split(",")
					tile_dict["icon_rect"].position = Vector2(int(icon_coords[0]), int(icon_coords[1]))
					var tile_size_string: String = autotile_tile_size.strings[2]
					var tile_sizes := tile_size_string.split(",")
					tile_dict["icon_rect"].size = Vector2(int(tile_sizes[0]), int(tile_sizes[1]))
				else: #error
					parse_result["error"] = true
				continue
			TileSet.AUTO_TILE:
				var bitmask_mode_regex := RegEx.new()
				bitmask_mode_regex.compile(
					str(tile_dict["id"]) + '/autotile/bitmask_mode\\s*=\\s(\\d+)\\s*' )
				var bitmask_mode_match: RegExMatch = bitmask_mode_regex.search(tiles_data)
				if bitmask_mode_match != null:
					var godot_bitmask_mode := int(bitmask_mode_match.strings[1])
					var bitmask_mode_index := Const.GODOT_AUTOTILE_GODOT_INDEXES.values().find(godot_bitmask_mode)
					if bitmask_mode_index != -1:
						tile_dict["bitmask_mode"] = Const.GODOT_AUTOTILE_GODOT_INDEXES.keys()[bitmask_mode_index]
				var shapes_regex := RegEx.new()
				shapes_regex.compile(
					str(tile_dict["id"]) + '/shapes\\s*=\\s*\\[\\s*' + 
					'([\\s\\S]*)' + 
					'\\s*\\]\\s*' + 
					str(tile_dict["id"]) + '/z_index')
				var shapes_search_result := shapes_regex.search(tiles_data)
				if shapes_search_result != null:
					var shapes_string: String = shapes_search_result.strings[1]
					if shapes_string.length() > 0:
						var one_shape_regex := RegEx.new()
						one_shape_regex.compile('\\{\\s*' + 
								'"autotile_coord": Vector2\\(\\s*(\\d+)\\,\\s*(\\d+)\\s*\\),\\s*' + 
								'"one_way": false,\\s*' +
								'"one_way_margin": .*,\\s*' +
								'"shape": SubResource\\(\\s*(\\d+)\\s*\\),\\s*' + 
								'"shape_transform": Transform2D\\(.*\\)\\s*' + 
								'\\}\\s*')
						for one_shape_result in one_shape_regex.search_all(shapes_string):
							var shape_id := int(one_shape_result.strings[3])
#							var shape_autotile_coord := Vector2(int(one_shape_result.strings[1]), int(one_shape_result.strings[2]))
#							print(shape_id, ": ", shape_autotile_coord)
							tile_dict["shape_ids"].append(shape_id)
		parse_result["tiles"].append(tile_dict)
	return parse_result


# load steps is the total number of resources (gd_resource + ext_resource + subresource)
func _resource_update_load_steps(tileset_content: String, new_load_steps: int) -> String:
	var load_steps_regex := RegEx.new()
	load_steps_regex.compile('\\[gd_resource\\s*type="TileSet"\\s*load_steps=(\\d+)')
	var load_steps_match: RegExMatch = load_steps_regex.search(tileset_content)
	if load_steps_match == null:
		var load_steps_insert_position = tileset_content.find("format")
		return tileset_content.insert(load_steps_insert_position, "load_steps=%d " % new_load_steps)
	var previous_load_steps: int = int(load_steps_match.strings[1])
	return tileset_content.replace("load_steps=%d" % previous_load_steps, "load_steps=%d" % new_load_steps)


func _resource_add_texture_resource(tileset_content: String, texture_id: int) -> String:
	var texture_string: String = make_texture_string(texture_path, texture_id)
	var last_ext_resource_position: int = tileset_content.find_last("[ext_resource")
	var texture_insert_position: int = 0
	if last_ext_resource_position != -1: # has ext_resources in tileset
		texture_insert_position = tileset_content.find("\n", last_ext_resource_position) + 1
	else:
		texture_insert_position = tileset_content.find("\n\n", 0) + 1
		texture_string = texture_string.insert(0, "\n")
	return tileset_content.insert(texture_insert_position, texture_string)


func _resource_add_collision_subresources(tileset_content: String, existing_subresources: Dictionary, 
		new_contours: Dictionary) -> String:
	var main_resource_position: int = tileset_content.find_last("\n[resource]")
	var max_id: int = existing_subresources.keys().max() if existing_subresources.keys().size() > 0 else 0
	return tileset_content.insert(main_resource_position, 
		"\n" + make_collision_subresources_string(new_contours, max_id + 1) + "\n")


func save_tileset_resource() -> bool:
	var file := File.new()
	var tileset_path: String = resource_path.get_basename() + ".tres"
	if overwrite_tileset_select.pressed:
		file.open(tileset_path, File.WRITE)
		file.store_string('[gd_resource type="TileSet" load_steps=1 format=2]\n\n[resource]\n')
		file.close()
	if not Helpers.file_exists(resource_path):
		report_error_inside_dialog("Error: tileset file does not exist on path: \n%s" % tileset_path)
		return false
	file.open(tileset_path, File.READ)
	var tileset_content := file.get_as_text()
	file.close()
	var project_path := get_godot_project_path(tileset_path)
	var tileset_resource_data := _parse_tileset(tileset_content, project_path)
	if tileset_resource_data["error"] != false:
		report_error_inside_dialog("Error parsing tileset")
		return false
	var updated_content: String = tileset_content
	var is_texture_found := false
	var tile_texture_id: int = 0
	for texture_id in tileset_resource_data["textures"]:
		if tileset_resource_data["textures"][texture_id]["path"] == texture_path:
			is_texture_found = true
			tile_texture_id = texture_id
	var resource_count: int = tileset_resource_data["textures"].size() + 1 # +1 for reqired top resource
	if not is_texture_found: # add new texture ext_resource
		if tileset_resource_data["textures"].keys().size() > 0:
			tile_texture_id = tileset_resource_data["textures"].keys().max() + 1
		else:
			tile_texture_id = 1
		updated_content = _resource_add_texture_resource(updated_content, tile_texture_id)
		resource_count += 1 # +1 for new texture and 
	var tile_id: int = 0
	var tile_found: bool = false
	for tile in tileset_resource_data["tiles"]:
		if tile_name == tile["name"]:
			tile_found = true
			tile_id = tile["id"]
			break
		else:
			tile_id = int(max(tile_id, tile["id"]))
	var tile_replace_tile_block_start := -1
	var tile_replace_tile_block_end := -1
	if tile_found:
		tile_replace_tile_block_start = updated_content.find("%d/name" % tile_id)
		if tile_replace_tile_block_start == -1:
			report_error_inside_dialog("Error parsing tileset while replacing tile")
			return false
		tile_replace_tile_block_end = updated_content.find("%d/z_index" % tile_id, tile_replace_tile_block_start)
		if tile_replace_tile_block_end == -1:
			report_error_inside_dialog("Error parsing tileset while replacing tile")
			return false
		var used_subresources_regex := RegEx.new()
		used_subresources_regex.compile('"shape": SubResource\\s*\\(\\s*(\\d+)\\s*\\)\\s*')
		for shape_id_result in used_subresources_regex.search_all(updated_content, 
				tile_replace_tile_block_start, tile_replace_tile_block_end):
			var subresource_id := int(shape_id_result.strings[1])
			var subresource_start := updated_content.find('[sub_resource type="ConvexPolygonShape2D" id=%d]' % subresource_id)
			var subresource_end := updated_content.find('\n\n', subresource_start)
			updated_content.erase(subresource_start, subresource_end - subresource_start + 2)
			tileset_resource_data["subresources"].erase(subresource_id)
	else:
		tile_id += 1
	if not tileset_resource_data["subresources"].empty(): # if there were subresources already
		resource_count += tileset_resource_data["subresources"].size()
	if collision_dialog.collisions_accepted_by_user and collisions_check.pressed:
		updated_content = _resource_add_collision_subresources(updated_content, 
			tileset_resource_data["subresources"], collision_dialog.collision_contours)
		resource_count += collision_dialog.collision_contours.size()
	updated_content = _resource_update_load_steps(updated_content, resource_count)
	var tile_string := make_autotile_data_string(current_tile_size, 
			current_tile_masks, current_texture_size, tile_name, 
			current_tile_spacing, autotile_type, tile_id, tile_texture_id)
	
	if not tile_found: # we add new
		updated_content += tile_string
	else: #we modify exisiting
		tile_replace_tile_block_start = updated_content.find("%d/name" % tile_id)
		tile_replace_tile_block_end = updated_content.find("%d/z_index" % tile_id, tile_replace_tile_block_start)
		tile_replace_tile_block_end = updated_content.find("\n", tile_replace_tile_block_end)
		updated_content.erase(tile_replace_tile_block_start, tile_replace_tile_block_end - tile_replace_tile_block_start + 1)
		updated_content = updated_content.insert(tile_replace_tile_block_start, tile_string)
	file.open(tileset_path, File.WRITE)
	file.store_string(updated_content)
#	print(updated_content.substr(0, 100))
	file.close()
	return true


func tile_name_from_position(pos: Vector2, tile_base_name: String) -> String:
	return "%s_%d_%d" % [tile_base_name, pos.x, pos.y]


func get_godot_project_path(path: String) -> String:
	var path_array := path.get_base_dir().split("/")
	var current_test_dir: String = ""
	for dir in path_array:
		current_test_dir += dir + "/"
		if Helpers.file_exists(current_test_dir + "project.godot"):
			return current_test_dir
	return ""


func project_export_relative_path(path: String) -> String:
	var path_array := path.get_base_dir().split("/")
	var current_test_dir: String = ""
	var project_found: bool = false
	var project_dir_index = 0
	for dir in path_array:
		current_test_dir += dir + "/"
		project_dir_index += 1
		if Helpers.file_exists(current_test_dir + "project.godot"):
			project_found = true
			break
	if project_found:
		var relative_path_array: Array = Array(path_array).slice(project_dir_index, len(path_array))
		relative_path_array.append(path.get_file())
		var relative_path: String = "res://" + PoolStringArray(relative_path_array).join("/")
		return relative_path
	return ""


func make_texture_string(tile_texture_path: String, texture_id: int = 1) -> String:
	var texture_relative_path := project_export_relative_path(tile_texture_path)
	return "[ext_resource path=\"%s\" type=\"Texture\" id=%d]\n" % [texture_relative_path, texture_id]


func make_autotile_data_string(tile_size: Vector2, tile_masks: Dictionary, 
		texture_size: Vector2, new_tile_name: String, 
		tile_spacing: int, new_autotile_type: int, 
		tile_id: int, texture_id: int) -> String:
	var out_string: String = ""
	var mask_out_strings: PoolStringArray = []
	var tile_collision_strings: PoolStringArray = []
	var line_beginning := str(tile_id) + "/"
	for mask in tile_masks:
		for tile in tile_masks[mask]:
			var tile_position: Vector2 = tile.position_in_template
			mask_out_strings.append("Vector2 ( %d, %d )" % [tile_position.x, tile_position.y])
			var godot_mask: int = Helpers.convert_bitmask_to_godot(tile.mask, new_autotile_type)
			mask_out_strings.append(str(godot_mask))
			if collision_dialog.collisions_accepted_by_user and collisions_check.pressed:
				if tile_position in collision_shapes_to_id:
					var collision_resource_id: int = collision_shapes_to_id[tile_position]
					tile_collision_strings.append(make_tile_shape_string(tile_position, collision_resource_id))
				else:
					print("ERROR: collision shape not found for autotile at poisition %s" % str(tile_position))
	var tile_shapes_string := ""
	if tile_collision_strings.size() > 0:
		tile_shapes_string = tile_collision_strings.join(", ")
	out_string += line_beginning + "name = \"%s\"\n" % new_tile_name
	out_string += line_beginning + "texture = ExtResource( %d )\n" % texture_id
	out_string += line_beginning + "tex_offset = Vector2( 0, 0 )\n"
	out_string += line_beginning + "modulate = Color( 1, 1, 1, 1 )\n"
	out_string += line_beginning + "region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += line_beginning + "tile_mode = 1\n" 
	out_string += line_beginning + "autotile/bitmask_mode = %d\n" % Const.GODOT_AUTOTILE_GODOT_INDEXES[new_autotile_type]
	out_string += line_beginning + "autotile/bitmask_flags = [ %s ]\n" % mask_out_strings.join(", ")
	out_string += line_beginning + "autotile/icon_coordinate = Vector2( 0, 0 )\n"
	out_string += line_beginning + "autotile/tile_size = Vector2( %d, %d )\n" % [tile_size.x, tile_size.y]
	out_string += line_beginning + "autotile/spacing = %d\n" % tile_spacing
	out_string += line_beginning + "autotile/occluder_map = [  ]\n"
	out_string += line_beginning + "autotile/navpoly_map = [  ]\n"
	out_string += line_beginning + "autotile/priority_map = [  ]\n"
	out_string += line_beginning + "autotile/z_index_map = [  ]\n"
	out_string += line_beginning + "occluder_offset = Vector2( 0, 0 )\n"
	out_string += line_beginning + "navigation_offset = Vector2( 0, 0 )\n"
	out_string += line_beginning + "shape_offset = Vector2( 0, 0 )\n"
	out_string += line_beginning + "shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )\n"
	out_string += line_beginning + "shape_one_way = false\n"
	out_string += line_beginning + "shape_one_way_margin = 0.0\n"
	out_string += line_beginning + "shapes = [ %s ]\n" % tile_shapes_string
	out_string += line_beginning + "z_index = 0\n"
	return out_string


func free_loaded_tile_rows_ui():
	for row in existing_tiles_container.get_children():
		if row != temp_tile_row:
			row.queue_free()


func load_tileset(tileset_path: String):
	var project_path := get_godot_project_path(tileset_path)
	if is_a_valid_resource_path(tileset_path):
		var tileset_name := tileset_path.get_file()
		var project_config := ConfigFile.new()
		project_config.load(project_path + "/project.godot")
		var project_name: String = str(project_config.get_value("application", "config/name"))
		if Helpers.file_exists(tileset_path):
			overwrite_tileset_select.disabled = false
			overwrite_tileset_select.pressed = false
			var tileset_file := File.new()
			tileset_file.open(tileset_path, File.READ)
			var tileset_content: String = tileset_file.get_as_text()
			tileset_file.close()
			var tileset_data := _parse_tileset(tileset_content, project_path)
			if tileset_data["error"] == false:
				free_loaded_tile_rows_ui()
				existing_tiles_container.remove_child(temp_tile_row)
				for tile in tileset_data["tiles"]:
					var existing_tile: GodotTileRow = preload("res://exporters/GodotExistingTileRow.tscn").instance()
					if tileset_data["textures"].has(tile["texture_id"]):
						var exisiting_texture_abs_path: String = tileset_data["textures"][tile["texture_id"]]["path"]
						var exisiting_texture_rel_path: String = tileset_data["textures"][tile["texture_id"]]["relative_path"]
						var exisiting_texture_image: Image = tileset_data["textures"][tile["texture_id"]]["image"]
						if not Helpers.file_exists(exisiting_texture_abs_path):
							report_error_inside_dialog("Texture used for tile \"%s\" is missing" % tile["name"])
						existing_tile.populate(
							tile["name"], 
							tile["id"],
							exisiting_texture_rel_path,
							exisiting_texture_image,
							tile["icon_rect"], 
							tile["tile_mode"], 
							tile["bitmask_mode"],
							tile["shape_ids"].size() > 0)
						existing_tiles_container.add_child(existing_tile)
						existing_tile.connect("clicked", self, "populate_new_from_exisiting_tile")
					else:
						overwrite_tileset_select.disabled = true
						overwrite_tileset_select.pressed = true
						report_error_inside_dialog("Error parsing tileset file, can only overwrite")
				existing_tiles_container.add_child(temp_tile_row)
			else:
				overwrite_tileset_select.disabled = true
				overwrite_tileset_select.pressed = true
				report_error_inside_dialog("Error parsing tileset file, can only overwrite")
			enable_tiles_editing(tileset_name, project_name)
			yield(get_tree(), "idle_frame")
			check_existing_for_matches()
		else:
			overwrite_tileset_select.disabled = true
			overwrite_tileset_select.pressed = true
			enable_tiles_editing(tileset_name, project_name)
			free_loaded_tile_rows_ui()
	else:
		report_error_inside_dialog("Error: Invalid tileset path")


func check_existing_for_matches():
	is_tile_match = false
	is_match_error_found = false
	var current_texture_relative_path := texture_path.replace(resource_path.get_base_dir() + "/", "")
	for row in existing_tiles_container.get_children():
		var tile_match: bool = row.tile_name == tile_name_edit.text and not row == temp_tile_row
		is_tile_match = is_tile_match or tile_match
		var texture_match: bool = row.texture_path == current_texture_relative_path and not row == temp_tile_row
		var error_duplicate_textures: bool = (not tile_match) and texture_match
		if not row == temp_tile_row:
			row.highlight_name(tile_match)
			row.highlight_path(texture_match, error_duplicate_textures)
			is_match_error_found = is_match_error_found or error_duplicate_textures
	if is_tile_match:
		temp_tile_row.hide()
	else:
		populate_temp_tile_from_inputs()
		temp_tile_row.show()
		scroll_deferred = true


func populate_new_from_exisiting_tile(row: GodotTileRow):
	tile_name = row.tile_name
	set_lineedit_text(tile_name_edit, tile_name)
	var base_dir_abs_path := get_godot_project_path(resource_path) + row.texture_path.get_base_dir()
	if base_dir_abs_path.ends_with("/"):
		base_dir_abs_path.erase(base_dir_abs_path.length() - 1, 1)
	var texture_file_name := row.texture_path.get_basename().get_file()
	set_texture_path(base_dir_abs_path, texture_file_name)
	autotile_type_select.select(row.bitmask_mode)
	check_existing_for_matches()


func is_a_valid_resource_path(test_resource_path: String):
	if test_resource_path.get_basename().get_file().empty() or not test_resource_path.get_file().is_valid_filename():
		report_error_inside_dialog("Error: %s is not a valid filename" % test_resource_path.get_file())
		return false
	var resource_project_path := get_godot_project_path(test_resource_path)	
	if resource_project_path.empty():
		return false
	else:
		return true


func is_a_valid_texture_path(test_texture_path: String, test_resource_path: String):
	if test_texture_path.get_basename().get_file().empty() or not test_texture_path.get_file().is_valid_filename():
		report_error_inside_dialog("Error: %s is not a valid filename" % test_texture_path.get_file())
		return false
	var resource_project_path := get_godot_project_path(test_resource_path)
	var texture_project_path := get_godot_project_path(test_texture_path)
	if texture_project_path.empty() or resource_project_path != resource_project_path:
		report_error_inside_dialog("Error: texture is not in the same Godot project with the resource")
		return false
	else:
		return true


func clear_file_path(path: String) -> String:
	if Helpers.file_exists(path):
		return path
	else:
		return Helpers.get_default_dir_path()


func load_defaults_from_settings(data: Dictionary):
	resource_path = Helpers.clear_path(data["godot_export_resource_path"])
	texture_path = Helpers.clear_path(data["godot_export_texture_path"])
	tile_name = data["godot_export_tile_name"]
	last_generated_tile_name = data["godot_export_last_generated_tile_name"]
	autotile_type = data["godot_autotile_type"]


func cancel_action():
	if error_dialog.visible:
		error_dialog.hide()
		_on_ErrorDialog_confirmed()
	elif resource_dialog.visible:
		resource_dialog.hide()
	elif texture_dialog.visible:
		texture_dialog.hide()
	elif collision_dialog.visible:
		collision_dialog.hide()
	else:
		hide()


func report_error_inside_dialog(text: String):
	error_dialog.dialog_text = text
	error_dialog.popup_centered()


func save_settings():
	emit_signal("settings_saved")


func _on_SelectResourceButton_pressed():
	resource_dialog.invalidate()
	resource_dialog.popup_centered()


func _on_SelectTextureButton_pressed():
	texture_dialog.invalidate()
	texture_dialog.popup_centered()


func set_lineedit_text(lineedit: LineEdit, text: String):
	lineedit.text = text
	lineedit.caret_position = text.length()


func texture_path_auto_name(basedir: String, texture_file_name: String) -> String:
	return basedir + "/" + texture_file_name + ".png"


func set_texture_path(basedir: String, texture_file_name: String):
	if texture_file_name.is_valid_filename():
		texture_path = texture_path_auto_name(basedir, texture_file_name)
		texture_dialog.current_path = texture_path
		set_lineedit_text(tile_texture_edit, texture_path)
		var relative_texture_path := project_export_relative_path(texture_path).replace("res://", "")
		temp_tile_row.set_texture_path(relative_texture_path)
	else:
		report_error_inside_dialog("Error: texture file name is invalid")


func enable_tiles_editing(tileset_name: String, project_name: String):
	new_tile_container.show()
	blocking_rect_tiles.hide()
	tiles_header.text = "Tileset:  \"%s\",   in project:  \"%s\"" % [tileset_name, project_name]


func block_tiles_editing():
	blocking_rect_tiles.show()
	new_tile_container.hide()
	tiles_header.text = DEFAULT_TILES_LABEL


func _on_ResourceFileDialog_file_selected(path: String):
	if is_a_valid_resource_path(path):
		resource_path = path
		set_lineedit_text(resource_name_edit, resource_path)
#		if texture_path == "":
		set_texture_path(resource_path.get_base_dir(), tile_name)
#		else:
#			set_texture_path(resource_path.get_base_dir(), texture_path)
		load_tileset(resource_path)
		save_settings()
	else:
		report_error_inside_dialog("Error: Invalid tileset path. \n\nGodot tileset file path should be: \n 1. a valid path  \n 2. inside any Godot projects tree")


func _on_ErrorDialog_confirmed():
	error_dialog.dialog_text = ""


func _on_LineEditName_text_changed(new_text):
	tile_name = new_text
	temp_tile_row.set_tile_name(new_text)
	check_existing_for_matches()
	save_settings()


func _on_OptionButton_item_selected(index):
	autotile_type = index
	temp_tile_row.set_tile_mode(TileSet.AUTO_TILE, autotile_type)
	save_settings()


func _on_TextureFileDialog_file_selected(path: String):
	if is_a_valid_texture_path(path, resource_path):
		set_texture_path(path.get_base_dir(), path.get_basename().get_file())
		check_existing_for_matches()
		save_settings()


func _on_ButtonCancel_pressed():
	hide()


func save_all_and_exit():
	current_texture_image.save_png(texture_path)
	if save_tileset_resource():
		save_settings()
		hide()


func _on_ButtonOk_pressed():
	if is_a_valid_resource_path(resource_path) and is_a_valid_texture_path(texture_path, resource_path):
		if not is_match_error_found:
			var tileset_file_exists := Helpers.file_exists(resource_path)
			var texture_file_exists := Helpers.file_exists(texture_path)
			if not tileset_file_exists and not texture_file_exists:
				save_all_and_exit()
			else:
				save_confirm_dialog.window_title = "Confirm overwriting files"
				save_confirm_dialog.dialog_text = "\nAre you sure you want to save tileset overwriting:"
				if tileset_file_exists:
					save_confirm_dialog.dialog_text += "\n\n - The tileset \"%s\"" % resource_path.get_file()
				if not overwrite_tileset_select.pressed:
					save_confirm_dialog.dialog_text += ", "
					if is_tile_match:
						save_confirm_dialog.dialog_text += "overwriting tile \"%s\"" % tile_name
					else:
						save_confirm_dialog.dialog_text += "adding tile \"%s\"\n" % tile_name
				if texture_file_exists:
					save_confirm_dialog.dialog_text += "\n - The texture \"%s\"\n" % texture_path.get_file()
				save_confirm_dialog.popup_centered()
		else:
			report_error_inside_dialog("Error: you are about to damage the existing tileset\n" + 
									"by overwriting texture that is used by another tile(s)")
	else:
		report_error_inside_dialog("Error: invalide resource or texture path")


func make_tile_shape_string(autotile_coord: Vector2, collision_shape_id: int) -> String:
	var out_string := "{\n"
	out_string += "\"autotile_coord\": Vector2( %d, %d ),\n" % [int(autotile_coord.x), int(autotile_coord.y)]
	out_string += "\"one_way\": false,\n"
	out_string += "\"one_way_margin\": 1.0,\n"
	out_string += "\"shape\": SubResource( %d ),\n" % collision_shape_id
	out_string += "\"shape_transform\": Transform2D( 1, 0, 0, 1, 0, 0 )\n}"
	return out_string


func make_collision_subresources_string(collision_contours: Dictionary, start_id: int = 1) -> String:
	var strings := PoolStringArray()
	collision_shapes_to_id = {}
	var id := start_id
	for polygon_position in collision_contours:
		var polygon: PoolVector2Array = collision_contours[polygon_position]
		var polygon_string := "[sub_resource type=\"ConvexPolygonShape2D\" id=%d]" % id
		polygon_string += "\npoints = PoolVector2Array( "
		var points := PoolStringArray()
		points.resize(polygon.size() * 2)
		for i in range(polygon.size()):
			points[i * 2] = str(stepify(polygon[i].x, 0.0001))
			points[i * 2 + 1] = str(stepify(polygon[i].y, 0.0001))
		polygon_string += points.join(", ") + " )"
		strings.append(polygon_string)
		collision_shapes_to_id[polygon_position] = id
		id += 1
	return strings.join("\n\n")


func on_collsions_dialog_hide():
	if not collision_dialog.collisions_accepted_by_user:
		collisions_check.pressed = false


func populate_temp_tile_from_inputs():
	var texture_relative_path: String = project_export_relative_path(texture_path).replace("res://", "")
	temp_tile_row.populate(
		tile_name,
		-1,
		texture_relative_path,
		current_texture_image,
		Rect2(Vector2.ZERO, current_tile_size),
		TileSet.AUTO_TILE,
		autotile_type,
		false,
		true
	)

func _on_OverrideCheckButton_toggled(button_pressed):
	if button_pressed:
		free_loaded_tile_rows_ui()
		populate_temp_tile_from_inputs()
		temp_tile_row.show()
	else:
		load_tileset(resource_path)


func _on_CollisionsCheckButton_toggled(button_pressed: bool):
	if button_pressed:
		collision_dialog.start(current_texture_image, current_tile_size, 
			current_tile_spacing, current_smoothing)
	else:
		collision_dialog.collisions_accepted_by_user = false
		collision_shapes_to_id = {}
	temp_tile_row.set_collisions(button_pressed)
