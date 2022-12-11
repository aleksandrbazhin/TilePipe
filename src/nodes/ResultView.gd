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
onready var scale_controls: ScaleControls = $VBoxContainer/HSplitContainer/Result/ScaleControls


func combine_result_from_tile(tile: TPTile):
	current_output_tile_size = tile.get_output_tile_size()
	current_subtile_spacing = tile.subtile_spacing
	if last_selected_frame >= tile.frames.size():
		last_selected_frame = 0
	scale_controls.set_current_scale(tile.ui_result_display_scale, true)
	for frame in tile.frames:
		frame.merge_result_from_subtiles(tile.template_size, current_output_tile_size, tile.subtile_spacing)
		if not last_selected_subtile_index in frame.parsed_template:
			last_selected_subtile_index = Vector2.ZERO
		append_output_texture(frame.result_texture, frame.index)


func append_output_texture(texture: Texture, frame_index: int):
	var frame: ResultFrameView = preload("res://src/nodes/ResultFrameView.tscn").instance()
	frame.texture = texture
	if frame != null:
		var image_size: Vector2 = frame.texture.get_size()
		frame.rect_min_size = image_size
	frame.set_frame_index(frame_index)
	result_texture_container.add_child(frame)
	frame.connect("mouse_entered", self, "clear_other_frames_selection", [frame, true, false])
	frame.connect("subtile_selected", self, "on_frame_subtile_selected")
	var scale: float = scale_controls.get_current_scale()
	var is_frame_selected: bool = last_selected_frame == frame_index
	frame.set_current_scale(Vector2(scale, scale), is_frame_selected)
	frame.setup_highlights(current_output_tile_size, current_subtile_spacing, Vector2.ZERO, frame_index)
	if is_frame_selected:
		frame.select_subtile(last_selected_subtile_index)
		frame.highlight_subtile(last_selected_subtile_index)


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
			clear_other_frames_selection(frame_view, true, true)
	last_selected_subtile_index = subtile_index
	last_selected_frame = frame_index


func clear_other_frames_selection(except: ResultFrameView, clear_highlights: bool, clear_selections: bool):
	for child in result_texture_container.get_children():
		if child != except:
			child.clear_subtile_overlays(clear_highlights, clear_selections)


func clear():
	bitmask_label.text = ""
	for frame in result_texture_container.get_children():
		frame.queue_free()
	selected_subtile_texture.texture = null


func _on_SingleTile_resized():
	on_frame_subtile_selected(last_selected_subtile_index, last_selected_frame)


func display_export_path(export_type: int):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	match export_type:
		Const.EXPORT_TILE.TEXTURE:
			export_path_edit.text = tile.export_png_path
		Const.EXPORT_TILE.GODOT3:
			export_path_edit.text = tile.export_godot3_resource_path
		Const.EXPORT_TILE.MULTITEXTURE:
			export_path_edit.text = tile.export_multiple_png_path
		_:
			export_path_edit.text = ""


func set_export_option(export_type: int):
	if export_type != Const.EXPORT_TILE_UNKNOWN:
		export_type_option.select(export_type)


func _on_Godot3ExportDialog_popup_hide():
	display_export_path(Const.EXPORT_TILE.GODOT3)
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
		Const.EXPORT_TILE.TEXTURE:
			var dialog := $ExportTextureFileDialog
			dialog.current_path = tile.export_png_path
			dialog.popup_centered()
		Const.EXPORT_TILE.GODOT3:
			var dialog: GodotExporter = $Godot3ExportDialog
			dialog.start_export_dialog(tile)
		Const.EXPORT_TILE.MULTITEXTURE:
			var dialog = $MutitextureExportDialog
			var itex := ImageTexture.new()
			itex.create_from_image(tile.glue_frames_into_image())
			dialog.setup(itex, tile.export_multiple_png_path)
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
	State.update_tile_param(TPTile.PARAM_EXPORT_TYPE, Const.EXPORT_TILE.TEXTURE, false)
	display_export_path(Const.EXPORT_TILE.TEXTURE)


func _on_ExportTextureFileDialog_popup_hide():
	State.popup_ended()


func _on_ExportTextureFileDialog_about_to_show():
	State.popup_started($ExportTextureFileDialog)


func _on_MutitextureExportDialog_popup_hide():
	display_export_path(Const.EXPORT_TILE.MULTITEXTURE)


func _on_ScaleControls_scale_changed(scale: float):
	for frame in result_texture_container.get_children():
		var is_frame_selected: bool = last_selected_frame == frame.frame_index
		frame.set_current_scale(Vector2(scale, scale), is_frame_selected)
	State.update_tile_param(TPTile.PARAM_UI_RESULT_DISPLAY_SCALE, scale, false)


func move_subtile_selection(delta: Vector2):
	var tile: TPTile = State.get_current_tile()
	if tile == null or tile.frames.empty() or tile.frames[0] == null:
		return
	var new_index := last_selected_subtile_index + delta
	if not new_index in tile.frames[0].parsed_template:
		if new_index.y < 0 and delta == Vector2.UP and last_selected_frame > 0:
			last_selected_frame -= 1
			new_index.y = tile.template_size.y - 1
		elif new_index.y > 0 and delta == Vector2.DOWN and last_selected_frame < tile.frames.size() - 1:
			last_selected_frame += 1
			new_index.y = 0
		else:
			new_index = last_selected_subtile_index
	last_selected_subtile_index = new_index
	var frame: ResultFrameView = result_texture_container.get_child(last_selected_frame)
	if frame == null:
		return
	frame.select_subtile(last_selected_subtile_index)
	frame.highlight_subtile(last_selected_subtile_index)


func _input(event: InputEvent):
	if not event is InputEventKey:
		return
	if not event.is_pressed():
		return
	if not result_texture_container.has_focus():
		return
	match event.scancode:
		KEY_UP, KEY_KP_8:
			move_subtile_selection(Vector2.UP)
			get_tree().set_input_as_handled()
		KEY_DOWN, KEY_KP_2:
			move_subtile_selection(Vector2.DOWN)
			get_tree().set_input_as_handled()
		KEY_LEFT, KEY_KP_4:
			move_subtile_selection(Vector2.LEFT)
			get_tree().set_input_as_handled()
		KEY_RIGHT, KEY_KP_6:
			move_subtile_selection(Vector2.RIGHT)
			get_tree().set_input_as_handled()


func _on_TextureContainer_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		result_texture_container.grab_focus()
