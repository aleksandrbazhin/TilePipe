class_name MultitextureExportDialog
extends WindowDialog


enum SPLIT_TYPE {BY_SUBTILE, BY_FRAME}


onready var path_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/PathLineEdit
onready var pattern_edit: LineEdit = $MarginContainer/VBoxContainer/PatternContainer/PatternLineEdit
onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
onready var type_option_button: OptionButton = $MarginContainer/VBoxContainer/SplitTypeContainer/OptionButton
onready var file_dialog: FileDialog = $FileDialog


func setup(result: Texture, path: String):
	clear()
	path_edit.text = path
	file_dialog.current_dir = path
	texture_rect.texture = result


func clear():
#	path_edit.text = ""
	for highlight in texture_rect.get_children():
		highlight.queue_free()


func _on_SelectDirButton_pressed():
	$FileDialog.popup_centered()


func _on_OptionButton_item_selected(index: int):
	match index:
		SPLIT_TYPE.BY_SUBTILE:
			pattern_edit.text = "{tile_name}_{subtile_bitmask}_{subtile_variant_index}.png"
			highlight_subtiles()
		SPLIT_TYPE.BY_FRAME:
			pattern_edit.text = "{tile_name}_frame_{frame_index}.png"
			highllight_frames()


func highlight_subtiles():
	clear()
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	var t_size := texture_rect.texture.get_size()
	var y_stretch := texture_rect.rect_size.y / t_size.y 
	var x_stretch := texture_rect.rect_size.x / t_size.x 
	var scale := min(x_stretch, y_stretch)
	var frame_width := t_size.x * scale
	var frame_height := t_size.y * scale / float(tile.frames.size())
	var texture_offset_x := (texture_rect.rect_size.x - frame_width) / 2.0
	var texture_offset_y := (texture_rect.rect_size.y - t_size.y * scale) / 2.0
	var tile_size := tile.get_output_tile_size() * scale
	for frame in tile.frames:
		var frame_offset_y: int = texture_offset_y + frame.index * frame_height
		for subtile_position in frame.parsed_template:
			var subtile: GeneratedSubTile = frame.parsed_template[subtile_position].get_ref()
			create_highlight(
				Vector2(
					texture_offset_x + tile_size.x * subtile_position.x, 
					frame_offset_y + tile_size.y * subtile_position.y), 
				subtile.bitmask,
				tile_size)


func highllight_frames():
	clear()
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	var t_size := texture_rect.texture.get_size()
	var y_stretch: float = float(texture_rect.rect_size.y) / float(t_size.y) 
	var x_stretch: float = float(texture_rect.rect_size.x) / float(t_size.x) 
	var scale := min(x_stretch, y_stretch)
	var frame_width := t_size.x * scale
	var frame_height := t_size.y * scale / tile.frames.size()
	var texture_offset_x := (texture_rect.rect_size.x - frame_width) / 2.0
	var texture_offset_y := (texture_rect.rect_size.y - t_size.y * scale) / 2.0
	for frame in tile.frames:
		create_highlight(
			Vector2(
				texture_offset_x, 
				texture_offset_y + frame.index * frame_height), 
			frame.index + 1, 
			Vector2(frame_width, frame_height))


func create_highlight(position: Vector2, index: int, size: Vector2 = Vector2(48, 48)):
	var highlight: PartHighlight = preload("res://src/nodes/PartHighlight.tscn").instance()
	highlight.rect_position = position
	highlight.set_hightlight_universal_size(size)
	texture_rect.add_child(highlight)
	highlight.set_id(index, true)
	highlight.set_hightlight_universal_size(size) # this is idiotic, since set_id moves part label, we have to call set_size twice


# "{tile_name}_frame_{frame_index}.png"
func export_frames(dir_path: String, tile: TPTile):
	var tile_name := tile.tile_file_name.get_basename().get_file()
	var base_path: String= dir_path + "/" + tile_name + "_frame_"
	for frame in tile.frames:
		var png_path := base_path + str(frame.index) + ".png"
		frame.result_texture.get_data().save_png(png_path)


# "{tile_name}_{subtile_bitmask}_{subtile_variant_index}.png"
func export_subtiles(dir_path: String, tile: TPTile):
	var tile_name := tile.tile_file_name.get_basename().get_file()
	var base_path: String = dir_path + "/" + tile_name + "_"
	var variant_index_map := {}
	for frame in tile.frames:
		for bitmask in frame.result_subtiles_by_bitmask:
			var png_path := base_path + str(bitmask) + "_"
			for subtile in frame.result_subtiles_by_bitmask[bitmask]:
				if bitmask in variant_index_map:
					variant_index_map[bitmask] += 1
				else:
					variant_index_map[bitmask] = 1
				png_path += str(variant_index_map[bitmask]) + ".png"
				subtile.image.save_png(png_path)


func _unhandled_key_input(event: InputEventKey):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if visible:
			if $FileDialog.visible:
				$FileDialog.hide()
			else:
				hide()


func _on_MutitextureExportDialog_about_to_show():
	yield(VisualServer, "frame_post_draw")
	type_option_button.selected = 0
	_on_OptionButton_item_selected(0)
	State.popup_started(null)


func _on_MutitextureExportDialog_popup_hide():
	State.popup_ended()


func _on_FileDialog_dir_selected(dir: String):
	path_edit.text = dir


func _on_Button_pressed():
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		State.report_error("Error using rendered tile!")
		return
	var dir_path: String = $FileDialog.current_dir
	var dir := Directory.new()
	if not dir.dir_exists(dir_path) or path_edit.text.empty():
		State.report_error("Invalid export directory.")
		return
	match type_option_button.selected:
		SPLIT_TYPE.BY_SUBTILE:
			export_subtiles(dir_path, tile)
		SPLIT_TYPE.BY_FRAME:
			export_frames(dir_path, tile)
	State.update_tile_param(TPTile.PARAM_EXPORT_MULTIPLE_PNG_PATH, dir_path)
	hide()


func _on_CancelButton_pressed():
	hide()
