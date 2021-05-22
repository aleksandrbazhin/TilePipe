extends PopupDialog

class_name GodotExporter



signal exporter_error(message)
signal settings_saved()

#var last_saved_data := {
#	"resource_path": "",
#	"texture_name": "",
#	"tile_name": "",
#	"last_generated_tile_name": "",
#	"autotile_type": Const.GODOT_AUTOTILE_TYPE.BLOB_3x3
#}

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

const DEFAULT_TILES_LABEL: String = "Select tileset to edit tiles ↑"

var resource_path: String = ""
var texture_path: String = ""
var tile_name: String = ""
# we need it to indentify tiles since it depends on input filename
var last_generated_tile_name: String = ""
var autotile_type: int = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3

# data passed from main window
var current_texture_image := Image.new()
var current_tile_size: int
var current_tile_masks: Array
var current_texture_size: Vector2
var current_tile_spacing: int

var is_tile_match: bool = false
var is_match_error_found: bool = false

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
onready var overwrite_tileset_select: CheckButton = $VBox/HBoxTileset/CheckButton

func convert_mask_to_godot(tile_mask: int, has_center: bool = true,
		godot_autotile_type: int = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3) -> int:
	var godot_mask: int = 0
	match autotile_type:
		Const.GODOT_AUTOTILE_TYPE.BLOB_3x3:
			for mask_name in GODOT_MASK_3x3.keys():
				if mask_name == "CENTER":
					if has_center:
						godot_mask += GODOT_MASK_3x3["CENTER"]
				else:
					var check_bit: int = Const.TILE_MASK[mask_name]
					if tile_mask & check_bit != 0:
						godot_mask += GODOT_MASK_3x3[mask_name]
		Const.GODOT_AUTOTILE_TYPE.WANG_2x2:
			for mask_name in GODOT_MASK_2x2.keys():
				var check_bit: int = Const.TILE_MASK[mask_name]
				if tile_mask & check_bit != 0:
					godot_mask += GODOT_MASK_2x2[mask_name]
	return godot_mask

# warn if there are not enough tiles for proper autotiling
func check_masks_with_warning(masks, godot_autotile_type):
	match godot_autotile_type:
		Const.GODOT_AUTOTILE_TYPE.BLOB_3x3:
			pass
		Const.GODOT_AUTOTILE_TYPE.WANG_2x2:
			pass

func save_tileset_resource() -> bool:
	var file := File.new()
	var tileset_path: String = resource_path.get_basename( ) + ".tres"
	if overwrite_tileset_select.pressed:
		var output_string := make_autotile_resource_data(
			current_tile_size, current_tile_masks,
			current_texture_size, texture_path, 
			tile_name, current_tile_spacing, autotile_type)
		file.open(tileset_path, File.WRITE)
		file.store_string(output_string)
		file.close()
	else:
		if not file.file_exists(resource_path):
			report_error_inside_dialog("Error: tileset file does not exisist on path: \n%s" % tileset_path)
			return false
		file.open(tileset_path, File.READ_WRITE)
		var tileset_content := file.get_as_text()
		var project_path := get_godot_project_path(tileset_path)
		var tileset_data := _parse_tileset(tileset_content, project_path)
		if tileset_data["error"] != false:
			file.close()
			report_error_inside_dialog("Error parsing tileset")
			return false
		var updated_content: String = tileset_content
		var is_texture_found := false
		var tile_texture_id: int = 0
		for texture_id in tileset_data["textures"]:
			if tileset_data["textures"][texture_id]["path"] == texture_path:
				is_texture_found = true
				tile_texture_id = texture_id
		if not is_texture_found: # add texture ext_resource
			tile_texture_id = tileset_data["textures"].keys().max() + 1
			var last_ext_resource_position: int = updated_content.find_last("[ext_resource")
			var texture_insert_position: int = 0
			print(last_ext_resource_position)
			if last_ext_resource_position != -1: # has ext_resources in tileset
				texture_insert_position = updated_content.find("\n", last_ext_resource_position) + 1
			else:
				texture_insert_position = updated_content.find("\n[resource]", 0) - 1
			var texture_string: String = make_texture_string(texture_path, tile_texture_id)
			updated_content = updated_content.insert(texture_insert_position, texture_string)
			# update load_steps here
			# load steps is the total number of resources (gd_resource + ext_resource)
			var load_steps: int = tileset_data["textures"].size() + 1 # existing textures + the top gd_resource
			load_steps += 1 # add the new texture
			var load_steps_regex := RegEx.new()
			load_steps_regex.compile('\\[gd_resource\\s*type="TileSet"\\s*load_steps=(\\d+)')
			var load_steps_match: RegExMatch = load_steps_regex.search(tileset_content)
			if load_steps_match == null:
				report_error_inside_dialog("Error parsing tileset: load_steps not found")
				return false
			else:
				var previous_load_steps: int = int(load_steps_match.strings[1])
				updated_content = updated_content.replace("load_steps=%d" % previous_load_steps, "load_steps=%d" % load_steps)
		print (updated_content)
		var tile_id: int = 0
		var tile_found: bool = false
		for tile in tileset_data["tiles"]:
			if tile_name == tile["name"]:
				tile_found = true
				tile_id = tile["id"]
				break
		print(tile_name, "  ", tile_id)
		if tile_found:
			pass
			#3. if we modify exsisting:
			#find tile's id
			#rewrite it's block fully
		else:
			pass
			#4. else:
			#find new_id = max_id + 1
			#create a new block
		
		file.close()

		

	return true
		

func tile_name_from_position(pos: Vector2, tile_base_name: String) -> String:
	return "%s_%d_%d" % [tile_base_name, pos.x, pos.y]

func get_godot_project_path(path: String) -> String:
	var path_array := path.get_base_dir().split("/")
	var current_test_dir: String = ""
	for dir in path_array:
		current_test_dir += dir + "/"
		var godot_project = File.new()
		if godot_project.file_exists(current_test_dir + "project.godot"):
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
		var godot_project = File.new()
		if godot_project.file_exists(current_test_dir + "project.godot"):
			project_found = true
			break
	if project_found:
		var relative_path_array: Array = Array(path_array).slice(project_dir_index, len(path_array))
		relative_path_array.append(path.get_file())
		var relative_path: String = "res://" 
		relative_path += PoolStringArray(relative_path_array).join("/")
		return relative_path
	return ""

func make_texture_string(tile_texture_path: String, texture_id: int = 1) -> String:
	return "[ext_resource path=\"%s\" type=\"Texture\" id=%d]\n" % [tile_texture_path, texture_id]

func make_autotile_resource_data(tile_size: int, tile_masks: Array, 
		texture_size: Vector2, new_texture_path: String, tile_base_name: String, 
		tile_spacing: int, new_autotile_type: int) -> String:
	var texture_relative_path := project_export_relative_path(new_texture_path)
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=2 format=2]\n"
	out_string += "\n" + make_texture_string(texture_relative_path, 1)
	out_string += "\n[resource]\n"
#	var texture_size: Vector2 = out_texture.texture.get_data().get_size()
	var mask_out_array: PoolStringArray = []
	check_masks_with_warning(tile_masks, new_autotile_type)
	for mask in tile_masks:
		mask_out_array.append("Vector2 ( %d, %d )" % [mask['position'].x, mask['position'].y])
		var godot_mask: int = convert_mask_to_godot(mask['mask'], mask['has_tile'], new_autotile_type)
		mask_out_array.append(str(godot_mask))
	out_string += "0/name = \"%s\"\n" % tile_base_name
	out_string += "0/texture = ExtResource( 1 )\n"
	out_string += "0/tex_offset = Vector2( 0, 0 )\n"
	out_string += "0/modulate = Color( 1, 1, 1, 1 )\n"
	out_string += "0/region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += "0/tile_mode = 1\n" 
	out_string += "0/autotile/bitmask_mode = %d\n" % Const.GODOT_AUTOTILE_GODOT_INDEXES[new_autotile_type]
	out_string += "0/autotile/bitmask_flags = [ %s ]\n" % mask_out_array.join(", ")
	out_string += "0/autotile/icon_coordinate = Vector2( 0, 0 )\n"
	out_string += "0/autotile/tile_size = Vector2( %d, %d )\n" % [tile_size, tile_size]
	out_string += "0/autotile/spacing = %d\n" % tile_spacing
	out_string += "0/autotile/occluder_map = [  ]\n"
	out_string += "0/autotile/navpoly_map = [  ]\n"
	out_string += "0/autotile/priority_map = [  ]\n"
	out_string += "0/autotile/z_index_map = [  ]\n"
	out_string += "0/occluder_offset = Vector2( 0, 0 )\n"
	out_string += "0/navigation_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )\n"
	out_string += "0/shape_one_way = false\n"
	out_string += "0/shape_one_way_margin = 0.0\n"
	out_string += "0/shapes = [  ]\n"
	out_string += "0/z_index = 0\n"
	return out_string

func _parse_tileset(tileset_file_content: String, project_path: String) -> Dictionary:
	var sections: PoolStringArray = tileset_file_content.split("[resource]", false, 1)
	var header: String = sections[0]
	var texture_regex := RegEx.new()
	texture_regex.compile('\\[ext_resource path="(.+)" type="Texture" id=(\\d+)\\]')
	var parse_result: Dictionary = {
		"textures": {},
		"tiles": [],
		"error": false # error during parsing tileset
	}
	var test_file := File.new()
	var textures: Dictionary = {}
	for texture_result in texture_regex.search_all(header):
		var texture_parsed_path: String = texture_result.strings[1]
		var texture_id: int = int(texture_result.strings[2])
		var texture_absolute_path: String = texture_parsed_path.replace("res://", project_path)
		textures[texture_id] = {
			"path": texture_absolute_path,
			"image": null,
			"error": false # error when miage does not exist
		}
		#TODO: check better
		if test_file.file_exists(texture_absolute_path):
			var exisiting_image: Image = Image.new()
			exisiting_image.load(texture_absolute_path)
			textures[texture_id]["image"] = exisiting_image
		else:
			textures[texture_id]["error"] = true
	parse_result["textures"] = textures
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
			"icon_rect": Rect2()
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
		parse_result["tiles"].append(tile_dict)
	return parse_result

func free_loaded_tile_rows():
	for row in existing_tiles_container.get_children():
		row.queue_free()

func load_tileset(tileset_path: String):
	var project_path := get_godot_project_path(tileset_path)
	var tileset_file := File.new()
	if tileset_file.file_exists(tileset_path) and is_a_valid_resource_path(tileset_path):
		overwrite_tileset_select.disabled = false
		overwrite_tileset_select.pressed = false
		tileset_file.open(tileset_path, File.READ)
		var tileset_content: String = tileset_file.get_as_text()
		tileset_file.close()
		var tileset_data := _parse_tileset(tileset_content, project_path)
		if tileset_data["error"] == false:
			free_loaded_tile_rows()
			for tile in tileset_data["tiles"]:
				var exisiting_tile: Godot_tile_row = preload("res://exporters/Godot_existing_tile_row.tscn").instance()
				if tileset_data["textures"].has(tile["texture_id"]):
					var exisiting_texture_path: String = tileset_data["textures"][tile["texture_id"]]["path"]
					exisiting_tile.populate(tile["name"], tile["id"], 
						exisiting_texture_path,
						tile["icon_rect"], tile["tile_mode"],
						tileset_data["textures"][tile["texture_id"]]["image"])
					existing_tiles_container.add_child(exisiting_tile)
					exisiting_tile.connect("clicked", self, "populate_from_exisiting_tile")
				else: 
					report_error_inside_dialog("Error parsing tileset file")
		else:
			report_error_inside_dialog("Error parsing tileset file")
		var tileset_name := tileset_path.get_file()
		var project_config := ConfigFile.new()
		project_config.load(project_path + "/project.godot")
		var project_name: String = str(project_config.get_value("application", "config/name"))
		new_tile_container.show()
		blocking_rect_tiles.hide()
		tiles_header.text = "Tileset:  \"%s\",   in project:  \"%s\"" % [tileset_name, project_name]
		check_existing_for_matches()
	else:
		overwrite_tileset_select.disabled = true
		overwrite_tileset_select.pressed = true
		free_loaded_tile_rows()
		
func check_existing_for_matches():
	is_tile_match = false
	is_match_error_found = false
	for row in existing_tiles_container.get_children():
		var tile_match: bool = row.tile_name == tile_name_edit.text
		is_tile_match = is_tile_match or tile_match
		var texture_match: bool = row.texture_path == tile_texture_edit.text
		var error_duplicate_textures: bool = (not tile_match) and texture_match
		row.highlight_name(tile_match)
		row.highlight_path(texture_match, error_duplicate_textures)
		is_match_error_found = is_match_error_found or error_duplicate_textures

func populate_from_exisiting_tile(row: Godot_tile_row):
	tile_name = row.tile_name
	set_lineedit_text(tile_name_edit, tile_name)
	set_texture_path(row.texture_path.get_base_dir(), row.texture_path.get_file().split(".")[0])
	check_existing_for_matches()

func is_a_valid_resource_path(test_resource_path: String):
	if test_resource_path.get_file().split(".")[0].empty() or not test_resource_path.get_file().is_valid_filename():
		report_error_inside_dialog("Error: %s is not a valid filename" % test_resource_path.get_file())
		return false
	var resource_project_path := get_godot_project_path(test_resource_path)	
	if resource_project_path.empty():
		report_error_inside_dialog("Error: saving resource not in any Godot project")
		return false
	else:
		return true

func is_a_valid_texture_path(test_texture_path: String, test_resource_path: String):
	if test_texture_path.get_file().split(".")[0].empty() or not test_texture_path.get_file().is_valid_filename():
		report_error_inside_dialog("Error: %s is not a valid filename" % test_texture_path.get_file())
		return false
	var resource_project_path := get_godot_project_path(test_resource_path)
	var texture_project_path := get_godot_project_path(test_texture_path)
	if texture_project_path.empty() or resource_project_path != resource_project_path:
		report_error_inside_dialog("Error: texture is not in the same Godot project with the resource")
		return false
	else:
		return true

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
	new_tile_container.hide()
	for type in Const.GODOT_AUTOTILE_TYPE:
		var type_id: int = Const.GODOT_AUTOTILE_TYPE[type]
		autotile_type_select.add_item(Const.GODOT_AUTOTILE_TYPE_NAMES[type_id], type_id)

func clear_file_path(path: String) -> String:
	var file := File.new()
	if file.file_exists(path):
		return path
	else:
		return Helpers.get_default_dir_path()

func start_export_dialog(new_tile_size: int, new_tile_masks: Array, 
		new_texture_size: Vector2, new_tile_base_name: String, 
		new_tile_spacing: int, texture_image: Image):
	current_tile_size = new_tile_size
	current_texture_size = new_texture_size
	current_tile_spacing = new_tile_spacing
	current_tile_masks = new_tile_masks.duplicate(true)
	current_texture_image.copy_from(texture_image)
	var generated_tile_name: String = new_tile_base_name + Const.TILE_SAVE_SUFFIX
	if last_generated_tile_name != generated_tile_name and tile_name.is_valid_filename():
		tile_name = generated_tile_name
		texture_path = texture_path_auto_name(texture_path.get_base_dir(), tile_name)
		last_generated_tile_name = generated_tile_name
		save_settings()
	set_lineedit_text(tile_name_edit, tile_name)
	texture_dialog.current_path = texture_path
	set_lineedit_text(tile_texture_edit, texture_path)
	autotile_type_select.selected = autotile_type	
	
	var file_checker := File.new()
	if file_checker.file_exists(resource_path):
		set_lineedit_text(resource_name_edit, resource_path)
		resource_dialog.current_path = resource_path
		if get_godot_project_path(resource_path) != "":
			load_tileset(resource_path)
		else:
			report_error_inside_dialog("Error: loading resource not belonging to any Godot project")
	else:
		overwrite_tileset_select.pressed = true
		overwrite_tileset_select.disabled = true
		if resource_path == Helpers.clear_path(Const.DEFAULT_GODOT_RESOURCE_PATH):
			set_lineedit_text(resource_name_edit, ".tres")
			resource_dialog.current_path = resource_path
		else:
			load_tileset(resource_path)
#			report_error_inside_dialog("Error: previously saved Godot resource is deleted")
#			set_lineedit_text(resource_name_edit, resource_path.get_file())
#			resource_dialog.current_path = resource_path
	popup_centered()

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
	else:
		report_error_inside_dialog("Error: texture file name is invalid")
	

func block_tiles_editing():
	blocking_rect_tiles.show()
	new_tile_container.hide()
	tiles_header.text = DEFAULT_TILES_LABEL


func _on_ResourceFileDialog_file_selected(path: String):
	if is_a_valid_resource_path(path):
		resource_path = path
		set_lineedit_text(resource_name_edit, resource_path)
		set_texture_path(resource_path.get_base_dir(), tile_name)
		load_tileset(resource_path)
		save_settings()

func _on_ErrorDialog_confirmed():
	error_dialog.dialog_text = ""

func _on_LineEditName_text_changed(new_text):
#	var texture_autopath_before: String = texture_path_auto_name(resource_path.get_base_dir(), tile_name)
#	if texture_path == texture_autopath_before:
#		set_texture_path(texture_path.get_base_dir(), tile_name)
#		tile_name_edit.grab_focus()
	tile_name = new_text
	check_existing_for_matches()
	save_settings()

func _on_OptionButton_item_selected(index):
	autotile_type = index
	save_settings()

func _on_TextureFileDialog_file_selected(path: String):
	if is_a_valid_texture_path(path, resource_path):
		set_texture_path(path.get_base_dir(), path.get_file().split(".")[0])
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
			var file := File.new()
			var tileset_file_exists := file.file_exists(resource_path)
			var texture_file_exists := file.file_exists(texture_path)
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

func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		free_loaded_tile_rows()
	else:
		load_tileset(resource_path)
