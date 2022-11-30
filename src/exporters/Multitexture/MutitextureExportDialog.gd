class_name MutitextureExportDialog
extends WindowDialog


enum SPLIT_TYPE {BY_SUBTILE, BY_FRAME}


onready var path_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/PathLineEdit
onready var pattern_edit: LineEdit = $MarginContainer/VBoxContainer/PatternContainer/PatternLineEdit
onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
onready var type_option_button: OptionButton = $MarginContainer/VBoxContainer/SplitTypeContainer/OptionButton


func setup(result: Texture):
	clear()
	texture_rect.texture = result


func clear():
	for highlight in texture_rect.get_children():
		highlight.queue_free()
	


func _on_MutitextureExportDialog_about_to_show():
	yield(VisualServer, "frame_post_draw")
	type_option_button.selected = 0
	_on_OptionButton_item_selected(0)


func _on_SelectDirButton_pressed():
	$FileDialog.show()


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
	var stretch := min(x_stretch, y_stretch)
	var frame_width := t_size.x * stretch
	var frame_height := t_size.y * stretch / float(tile.frames.size())
	var texture_offset_x := (texture_rect.rect_size.x - frame_width) / 2.0
	var texture_offset_y := (texture_rect.rect_size.y - t_size.y * stretch) / 2.0
	var tile_size := tile.output_tile_size * stretch

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
	var stretch := min(x_stretch, y_stretch)
	var frame_width := t_size.x * stretch
	var frame_height := t_size.y * stretch / tile.frames.size()
	var texture_offset_x := (texture_rect.rect_size.x - frame_width) / 2.0
	var texture_offset_y := (texture_rect.rect_size.y - t_size.y * stretch) / 2.0
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


func _on_Button_pressed():
	hide()


func _on_CancelButton_pressed():
	hide()




func _unhandled_key_input(event: InputEventKey):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if visible:
			if $FileDialog.visible:
				$FileDialog.hide()
			else:
				hide()
