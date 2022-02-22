extends VBoxContainer

class_name InputTextureView

signal file_dialog_started()
signal file_dialog_ended()
signal report_error(text)
signal tile_texture_changed(path)

var current_texture_path := ""
var current_input_tile_size := Const.DEFAULT_TILE_SIZE

onready var tile_name := $HeaderContainer/TileNameLabel
onready var texture_option := $HeaderContainer/TextureFileName
onready var texture_container: ScalableTextureContainer = $HBox/ScalableTextureContainer

func load_data(tile: TileInTree):
	print(tile.tile_size)
	tile_name.text = tile.tile_file_name
	current_texture_path = tile.texture_path
	current_input_tile_size = tile.tile_size
	populate_texture_options()
	if current_texture_path != "":
		load_texture(tile.loaded_texture)


func populate_texture_options():
	texture_option.clear()
	var templates_found := scan_for_textures(Const.current_dir)
	var index := 0
	for texture_path in templates_found:
		texture_option.add_item(texture_path.get_file())
		texture_option.set_item_metadata(index, texture_path)
		if texture_path == current_texture_path:
			texture_option.selected = index
		index += 1


func scan_for_textures(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file.begins_with("."):
			continue
		elif file == "":
			break
		elif dir.dir_exists(file) and file != Const.TEMPLATE_DIR and file != Const.RULESET_DIR:
			files.append_array(scan_for_textures(path + "/" + file))
		elif file.get_extension() == "png":
			files.append(path + "/" + file)
	dir.list_dir_end()
	return files


func load_texture(texture: Texture):
	texture_container.set_texture(texture, current_input_tile_size)
	

func _on_TextureFileName_item_selected(index: int):
	current_texture_path = texture_option.get_item_metadata(index)
	emit_signal("tile_texture_changed", current_texture_path)


func _on_TextureDialogButton_pressed():
	$AddTextureFileDialog.popup_centered()


func _on_AddTextureFileDialog_about_to_show():
	emit_signal("file_dialog_started")


func _on_AddTextureFileDialog_popup_hide():
	emit_signal("file_dialog_ended")


func _on_AddTextureFileDialog_file_selected(path: String):
	var new_texture_path := Const.current_dir + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_texture_path)
	if error == OK:
		current_texture_path = new_texture_path
		populate_texture_options()
		emit_signal("tile_texture_changed", current_texture_path)
	else:
		emit_signal("report_error", "Error: Copy file error number %d." % error)
