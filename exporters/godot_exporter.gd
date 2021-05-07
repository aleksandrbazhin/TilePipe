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

var resource_path: String = ""
var texture_path: String = ""
var tile_name: String = ""
var last_generated_tile_name: String = ""
var autotile_type: int = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3

onready var resource_name_edit: LineEdit = $VBox/HBoxTileset/ResourceNameEdit
onready var tile_name_edit: LineEdit = $VBox/TilesPanelContainer/VBox/HBoxNewTile/LineEditName
onready var tile_texture_edit: LineEdit = $VBox/TilesPanelContainer/VBox/HBoxNewTile/LineEditTexture
onready var autotile_type_select: OptionButton = $VBox/TilesPanelContainer/VBox/HBoxNewTile/OptionButton

func save_resource(path: String, tile_size: int, tile_masks: Array, 
		texture_size: Vector2, new_texture_path: String, tile_base_name: String, 
		tile_spacing: int):
	var output_string : String
	output_string = make_autotile_resource_data(path, tile_size, 
		tile_masks, texture_size, new_texture_path, tile_base_name, tile_spacing)
	var tileset_resource_path: String = path.get_basename( ) + ".tres"
	var file = File.new()
	file.open(tileset_resource_path, File.WRITE)
	file.store_string(output_string)
	file.close()

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

func make_autotile_resource_data(path: String, tile_size: int, tile_masks: Array, 
		texture_size: Vector2, new_texture_path: String, tile_base_name: String, 
		tile_spacing: int) -> String:
	var texture_relative_path := project_export_relative_path(new_texture_path)
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=3 format=2]\n"
	out_string += "\n[ext_resource path=\"%s\" type=\"Texture\" id=1]\n" % texture_relative_path
	out_string += "\n[resource]\n"
#	var texture_size: Vector2 = out_texture.texture.get_data().get_size()
	var mask_out_array: PoolStringArray = []
	for mask in tile_masks:
		mask_out_array.append("Vector2 ( %d, %d )" % [mask['position'].x, mask['position'].y])
		mask_out_array.append(mask['godot_mask'])
	out_string += "0/name = \"%s\"\n" % tile_base_name
	out_string += "0/texture = ExtResource( 1 )\n"
	out_string += "0/tex_offset = Vector2( 0, 0 )\n"
	out_string += "0/modulate = Color( 1, 1, 1, 1 )\n"
	out_string += "0/region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += "0/tile_mode = 1\n"
	out_string += "0/autotile/bitmask_mode = 1\n"
	out_string += "0/autotile/bitmask_flags = [%s]\n" % mask_out_array.join(", ")
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


func check_resource_path(test_resource_path: String):
	if test_resource_path.get_file().split(".")[0].empty() or not test_resource_path.get_file().is_valid_filename():
		report_error_inside_dialog("Error: %s is not a valid filename" % test_resource_path.get_file())
		return false
	var resource_project_path := get_godot_project_path(test_resource_path)	
	if resource_project_path.empty():
		report_error_inside_dialog("Error: saving resource not in any Godot project path")
		return false
	else:
		return true

func check_texture_path(test_texture_path: String, test_resource_path: String):
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

func check_paths(test_resource_path: String, test_texture_path: String) -> bool:
	return check_resource_path(test_resource_path) and check_texture_path(test_texture_path, test_resource_path)


func _ready():
	$ResourceFileDialog.connect("popup_hide", $ColorRect, "hide")
	$ResourceFileDialog.connect("about_to_show", $ColorRect, "show")
	$TextureFileDialog.connect("popup_hide", $ColorRect, "hide")
	$TextureFileDialog.connect("about_to_show", $ColorRect, "show")
	$ErrorDialog.connect("popup_hide", $ColorRect, "hide")
	$ErrorDialog.connect("about_to_show", $ColorRect, "show")
	for type in Const.GODOT_AUTOTILE_TYPE:
		var type_id: int = Const.GODOT_AUTOTILE_TYPE[type]
		autotile_type_select.add_item(Const.GODOT_AUTOTILE_TYPE_NAMES[type_id], type_id)
	

func start_export_dialog(new_tile_size: int, new_tile_masks: Array, 
		new_texture_size: Vector2, new_tile_base_name: String, 
		new_tile_spacing: int):

	$ResourceFileDialog.current_path = resource_path
	set_lineedit_text(resource_name_edit, resource_path)

	var generated_tile_name: String = new_tile_base_name + Const.TILE_SAVE_SUFFIX
	if last_generated_tile_name != generated_tile_name:
		tile_name = generated_tile_name
		last_generated_tile_name = generated_tile_name
		save_settings()
	set_lineedit_text(tile_name_edit, tile_name)
	$TextureFileDialog.current_path = texture_path
	set_lineedit_text(tile_texture_edit, texture_path)
	autotile_type_select.selected = autotile_type
	popup_centered()

func load_defaults_from_settings(data: Dictionary):
	resource_path = Helpers.clear_path(data["godot_export_resource_path"])
	texture_path = Helpers.clear_path(data["godot_export_texture_path"])
	tile_name = data["godot_export_tile_name"]
	last_generated_tile_name = data["godot_export_last_generated_tile_name"]
	autotile_type = data["godot_autotile_type"]

func cancel_action():
	if $ErrorDialog.visible:
		$ErrorDialog.hide()
		_on_ErrorDialog_confirmed()
	elif $ResourceFileDialog.visible:
		$ResourceFileDialog.hide()
	elif $TextureFileDialog.visible:
		$TextureFileDialog.hide()
	else:
		hide()

func report_error_inside_dialog(text: String):
	$ErrorDialog.dialog_text = text
	$ErrorDialog.popup_centered()

func save_settings():
	emit_signal("settings_saved")

func _on_ButtonCancel_pressed():
	hide()

func _on_SelectResourceButton_pressed():
	$ResourceFileDialog.popup_centered()

func _on_SelectTextureButton_pressed():
	$TextureFileDialog.popup_centered()

func set_lineedit_text(lineedit: LineEdit, text: String):
	lineedit.text = text
	lineedit.caret_position = text.length()

func texture_path_auto_name(basedir: String, texture_file_name: String) -> String:
	return basedir + "/" + texture_file_name + ".png"
	
func set_texture_path(basedir: String, texture_file_name: String):
	texture_path = texture_path_auto_name(basedir, texture_file_name)
	$TextureFileDialog.current_path = texture_path
	set_lineedit_text(tile_texture_edit, texture_path)

func _on_ResourceFileDialog_file_selected(path: String):
	if check_resource_path(path):
#		var project_path := get_godot_project_path(path)
		resource_path = path
		set_lineedit_text(resource_name_edit, resource_path)
		set_texture_path(resource_path.get_base_dir(), tile_name)
		save_settings()
	else:
		pass

func _on_ErrorDialog_confirmed():
	$ErrorDialog.dialog_text = ""

func _on_LineEditName_text_changed(new_text):
	var texture_autopath_before: String = texture_path_auto_name(resource_path.get_base_dir(), tile_name)
	tile_name = new_text
	if texture_path == texture_autopath_before:
		set_texture_path(texture_path.get_base_dir(), tile_name)
		tile_name_edit.grab_focus()
	save_settings()

func _on_OptionButton_item_selected(index):
	autotile_type = index
	save_settings()

func _on_ButtonOk_pressed():
	if check_paths(resource_path, texture_path):
		save_settings()
		hide()

func _on_TextureFileDialog_file_selected(path: String):
	if check_texture_path(path, resource_path):
		set_texture_path(path.get_base_dir(), path.get_file().split(".")[0])
		save_settings()
