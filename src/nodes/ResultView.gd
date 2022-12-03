class_name ResultView
extends ColorRect


export var single_tile_visible := true
export var controls_visible := true

var last_selected_subtile_index := Vector2.ZERO
var last_selected_frame := 0
var current_output_tile_size: Vector2
var current_subtile_spacing := Vector2.ZERO

onready var selected_subtile_container := $VBoxContainer/HSplitContainer/SingleTile
onready var selected_subtile_texture := $VBoxContainer/HSplitContainer/SingleTile/SubtileTexture
onready var result_texture_container: = $VBoxContainer/HSplitContainer/Result/TextureContainer/VBoxContainer
onready var bitmask_label := $VBoxContainer/HSplitContainer/SingleTile/BitmaskLabel
onready var export_type_option := $VBoxContainer/ExportContainer/ExportOptionButton
onready var export_path_edit := $VBoxContainer/ExportContainer/ExportPathLineEdit


func combine_result_from_tile(tile: TPTile):
#	if tile == null:
#		return
	current_output_tile_size = tile.get_output_tile_size()
	current_subtile_spacing = tile.subtile_spacing
	if last_selected_frame >= tile.frames.size():
		last_selected_frame = 0
	for frame in tile.frames:
		var subtiles_by_bitmasks: Dictionary = frame.result_subtiles_by_bitmask
		if subtiles_by_bitmasks.empty():
			return
		var out_image := Image.new()
		var out_image_size: Vector2 = tile.template_size * current_output_tile_size
		out_image_size += (tile.template_size - Vector2.ONE) * tile.subtile_spacing
		out_image.create(int(out_image_size.x), int(out_image_size.y), false, Image.FORMAT_RGBA8)
		var tile_rect := Rect2(Vector2.ZERO, current_output_tile_size)
		var itex = ImageTexture.new()
		itex.create_from_image(out_image, 0)
		for mask in subtiles_by_bitmasks.keys():
			for tile_variant_index in range(subtiles_by_bitmasks[mask].size()):
				var subtile: GeneratedSubTile = subtiles_by_bitmasks[mask][tile_variant_index]
				var tile_position: Vector2 = subtile.position_in_template * current_output_tile_size
				tile_position +=  subtile.position_in_template * tile.subtile_spacing
				if subtile.image == null:
					continue
				out_image.blit_rect(subtile.image, tile_rect, tile_position)
				itex.set_data(out_image)
		frame.set_result_texture(itex)
		if not last_selected_subtile_index in frame.parsed_template:
			last_selected_subtile_index = Vector2.ZERO
		append_output_texture(itex, frame.index)


func append_output_texture(texture: Texture, frame_index: int):
	var result_frame_view: ResultFrameView = preload("res://src/nodes/ResultFrameView.tscn").instance()
	result_frame_view.texture = texture
	if result_frame_view != null:
		var image_size: Vector2 = result_frame_view.texture.get_size()
		result_frame_view.rect_size = image_size
	result_texture_container.add_child(result_frame_view)
	result_frame_view.setup_highlights(current_output_tile_size, current_subtile_spacing, Vector2.ZERO, frame_index)
	result_frame_view.connect("mouse_entered", self, "clear_other_frames", [result_frame_view, true, false])
	result_frame_view.connect("subtile_selected", self, "on_frame_subtile_selected")
	if frame_index == last_selected_frame:
		result_frame_view.select_subtile(last_selected_subtile_index)
		result_frame_view.highlight_subtile(last_selected_subtile_index)


func on_frame_subtile_selected(subtile_index: Vector2, frame_index: int):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		selected_subtile_texture.texture = null
		return
	if tile.frames.empty():
		return
	if not subtile_index in tile.frames[frame_index].parsed_template:
		selected_subtile_texture.texture = null
		bitmask_label.text = "No"
		return
#	if result_texture_container.get_child_count() == 0:
#		selected_subtile_texture.texture = null
#		print("tile == null3")
#		return
	var subtile_ref: WeakRef = tile.frames[frame_index].parsed_template[subtile_index]
	if subtile_ref == null:
		selected_subtile_texture.texture = null
		selected_subtile_texture.hide()
		bitmask_label.text = "?"
	else:
		var resize_to := min(selected_subtile_container.rect_size.x, selected_subtile_container.rect_size.y)
		var resize_from := min(current_output_tile_size.x, current_output_tile_size.y)
		if resize_from == 0:
			selected_subtile_texture.texture = null
			selected_subtile_texture.hide()
			return
		var scale := resize_to / resize_from
		var subtile: GeneratedSubTile = subtile_ref.get_ref()
		var itex := ImageTexture.new()
		if subtile.image != null:
			itex.create_from_image(subtile.image, 0)
			selected_subtile_texture.show()
		else:
			selected_subtile_texture.texture = null
			selected_subtile_texture.hide()
			bitmask_label.text = "No"
		itex.set_size_override(current_output_tile_size * scale)
		selected_subtile_texture.texture = itex
		bitmask_label.text = str(subtile.bitmask)
		State.emit_signal("subtile_selected", subtile.bitmask)
		var frame_view: ResultFrameView = result_texture_container.get_child(frame_index)
		if frame_index != null:
			clear_other_frames(frame_view, true, true)
	last_selected_subtile_index = subtile_index
	last_selected_frame = frame_index


func clear_other_frames(except: ResultFrameView, clear_highlights: bool, clear_selections: bool):
	for child in result_texture_container.get_children():
		if child != except:
			child.clear_subtile_overlays(clear_highlights, clear_selections)


func clear():
	bitmask_label.text = ""
	for child in result_texture_container.get_children():
		child.queue_free()
	last_selected_subtile_index = Vector2.ZERO
	last_selected_frame = 0
	selected_subtile_texture.texture = null


func _on_SingleTile_resized():
	on_frame_subtile_selected(last_selected_subtile_index, 0)


#func move_selection(delta:Vector2, frame_index: int = 0):
#	var tile: TPTile = State.get_current_tile()
#	if tile == null:
#		return
#	var new_index := last_selected_subtile_index + delta
#	if new_index in tile.frames[frame_index].parsed_template:
#		select_subtile(new_index)


#
#func _unhandled_input(event: InputEvent):
#	if event is InputEventKey and event.pressed:
#		match event.scancode:
#			KEY_UP:
#				move_selection(Vector2.UP)
#				get_tree().set_input_as_handled()
#			KEY_DOWN:
#				move_selection(Vector2.DOWN)
#				get_tree().set_input_as_handled()
#			KEY_LEFT:
#				move_selection(Vector2.LEFT)
#				get_tree().set_input_as_handled()
#			KEY_RIGHT:
#				move_selection(Vector2.RIGHT)
#				get_tree().set_input_as_handled()



func display_export_path(export_type: int):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	match export_type:
		Const.EXPORT_TYPES.TEXTURE:
			export_path_edit.text = tile.export_png_path
		Const.EXPORT_TYPES.GODOT3:
			export_path_edit.text = tile.export_godot3_resource_path
		Const.EXPORT_TYPES.MULTITEXTURE:
			pass
		_:
			export_path_edit.text = ""


func set_export_option(export_type: int):
	if export_type != Const.EXPORT_TYPE_UKNOWN:
		export_type_option.select(export_type)


func _on_Godot3ExportDialog_popup_hide():
	display_export_path(Const.EXPORT_TYPES.GODOT3)
	State.popup_ended()


func _on_ExportOptionButton_item_selected(index: int):
	display_export_path(index)
	State.update_tile_param(TPTile.PARAM_EXPORT_TYPE, index, false)


func _on_ExportButton_pressed():
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	if tile.frames[0].result_texture == null or tile.frames[0].result_texture.get_data() == null:
		State.report_error("Error: No generated texture, tile not fully defined")
		return
	match export_type_option.selected:
		Const.EXPORT_TYPES.TEXTURE:
			var dialog := $ExportTextureFileDialog
			dialog.current_path = tile.export_png_path
			dialog.popup_centered()
		Const.EXPORT_TYPES.GODOT3:
			var dialog: GodotExporter = $Godot3ExportDialog
			dialog.start_export_dialog(tile)
		Const.EXPORT_TYPES.MULTITEXTURE:
			var dialog = $MutitextureExportDialog
			var itex := ImageTexture.new()
			itex.create_from_image(tile.glue_frames_into_image())
			dialog.setup(itex)
			dialog.popup_centered()
			


func _on_ExportTextureFileDialog_file_selected(path):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	var result_image: Image = tile.glue_frames_into_image()
	if result_image == null:
		return
	result_image.save_png(path)
	State.update_tile_param(TPTile.PARAM_EXPORT_PNG_PATH, path, false)
	State.update_tile_param(TPTile.PARAM_EXPORT_TYPE, Const.EXPORT_TYPES.TEXTURE, false)
	display_export_path(Const.EXPORT_TYPES.TEXTURE)


func _on_ExportTextureFileDialog_popup_hide():
	State.popup_ended()


func _on_ExportTextureFileDialog_about_to_show():
	State.popup_started($ExportTextureFileDialog)

