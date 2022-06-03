extends VBoxContainer

class_name InputTextureView

#signal tile_texture_changed(path)
#signal tile_size_changed(size)
#signal merge_level_changed(level)
#signal overlap_level_changed(level)

var current_texture_path := ""
var current_input_tile_size := Const.DEFAULT_TILE_SIZE


onready var texture_option := $HeaderContainer/TextureFileName
onready var texture_container: ScalableTextureContainer = $HBox/ScalableTextureContainer
onready var merge_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeXSliderContainer/RateSlider
onready var merge_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeYSliderContainer/RateSlider
onready var overlay_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapXSliderContainer/OverlapSlider
onready var overlay_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapYSliderContainer/OverlapSlider


func load_data(tile: TileInTree):
	current_texture_path = tile.texture_path
	current_input_tile_size = tile.input_tile_size
	populate_texture_options()
	setup_sliders()
	merge_slider_x.value = tile.merge_level.x
	merge_slider_y.value = tile.merge_level.y
	overlay_slider_x.value = tile.overlap_level.x
	overlay_slider_y.value = tile.overlap_level.y
	if current_texture_path != "":
		load_texture(tile.loaded_texture)


func populate_texture_options():
	texture_option.clear()
	var templates_found := scan_for_textures(State.current_dir)
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
	

func setup_sliders():
	merge_slider_x.quantize(int(current_input_tile_size.x / 2))
	merge_slider_y.quantize(int(current_input_tile_size.y / 2))
	overlay_slider_x.quantize(int(current_input_tile_size.x / 2))
	overlay_slider_y.quantize(int(current_input_tile_size.y / 2))


func _on_TextureFileName_item_selected(index: int):
	current_texture_path = texture_option.get_item_metadata(index)
	State.update_tile_texture(current_texture_path)
	load_data(State.current_tile_ref.get_ref())


func _on_TextureDialogButton_pressed():
	$AddTextureFileDialog.popup_centered()


func _on_AddTextureFileDialog_about_to_show():
	State.popup_started($AddTextureFileDialog)


func _on_AddTextureFileDialog_popup_hide():
	State.popup_ended()


func _on_AddTextureFileDialog_file_selected(path: String):
	var new_texture_path := State.current_dir + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_texture_path)
	if error == OK:
		current_texture_path = new_texture_path
		populate_texture_options()
		State.update_tile_texture(current_texture_path)
		load_data(State.current_tile_ref.get_ref())
#		emit_signal("tile_texture_changed", current_texture_path)
	else:
		State.report_error("Error: Copy file error number %d." % error)


func _on_ScalableTextureContainer_tile_size_changed(size: Vector2):
#	emit_signal("tile_size_changed", size)
	State.update_tile_size(size)
	current_input_tile_size = size
	setup_sliders()
	


func _on_RateSlider_released(value: float):
	State.update_tile_merge_level(Vector2(value, value))


func _on_OverlapSlider_released(value: float):
	State.update_tile_overlap_level(Vector2(value, value))


func change_part_highlight(part_id: int, is_on: bool):
	texture_container.set_part_highlight(part_id, is_on)
