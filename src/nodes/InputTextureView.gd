class_name InputTextureView
extends VBoxContainer


var current_texture_path := ""
var current_input_tile_size := Vector2.ZERO

onready var texture_option := $HeaderContainer/TextureOption
onready var texture_container: ScalableTextureContainer = $HBox/ScalableTextureContainer
onready var merge_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeXSliderContainer/MergeSliderX
onready var merge_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeYSliderContainer/MergeSliderY
onready var overlap_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapXSliderContainer/OverlapSliderX
onready var overlap_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapYSliderContainer/OverlapSliderY
onready var output_resize: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/OutputResize/OutpuResizeButton
onready var output_tile_size_x: AdvancedSpinBox = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/OutputResize/ResizeSpinBoxX
onready var subtile_spacing_x: AdvancedSpinBox = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/SubtileSpacing/SpacingXSpinBox
onready var subtile_spacing_y: AdvancedSpinBox = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/SubtileSpacing/SpacingYSpinBox
onready var smoothing_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/SmoothingContainer/Smoothing
onready var random_seed_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/SeedContainer/RandomCheckButton
onready var random_seed_edit: LineEdit = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/SeedContainer/SeedLineEdit
onready var random_seed_apply: Button = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/SeedContainer/SeedButton
onready var parts_container := $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/PartSetupContainer/ScrollContainer/PartsContainer


func load_data(tile: TPTile):
	if tile == null:
		return
	current_texture_path = tile.texture_path
	current_input_tile_size = tile.input_tile_size
	populate_texture_option()
	setup_sliders()
	load_texture(tile.loaded_texture)
	output_resize.pressed = tile.output_resize
	output_tile_size_x.editable = tile.output_resize
	output_tile_size_x.value = tile.output_tile_size.x
	subtile_spacing_x.value = tile.subtile_spacing.x
	smoothing_enabled.pressed = tile.smoothing
	random_seed_enabled.pressed = tile.random_seed_enabled
	random_seed_edit.text = str(tile.random_seed_value)
	populate_frame_control()


func populate_frame_control():
	return
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	for part in parts_container.get_children():
		part.queue_free()
	if tile.loaded_ruleset == null:
		return
	var ruleset_parts := tile.loaded_ruleset.parts
	for part_index in tile.input_parts:
		if part_index >= ruleset_parts.size():
			break
		var frames_container := VBoxContainer.new()
		for part in tile.input_parts[part_index]:
			var frame_control: PartFrameControl = preload("res://src/nodes/PartFrameControl.tscn").instance()
			frame_control.setup(ruleset_parts[part.part_index], part.variant_index)
			frames_container.add_child(frame_control)
			frame_control.connect("part_frequency_click", self, "on_part_frequency_edit_start")
		parts_container.add_child(frames_container)


func on_part_frequency_edit_start(part: PartFrameControl):
	pass


func clear():
	texture_option.selected = texture_option.get_item_count() - 1
#	texture_container.set_main_texture(null)
	texture_container.clear()
	for part in parts_container.get_children():
		part.queue_free()


func load_texture(texture: Texture):
	texture_container.set_main_texture(texture)


func setup_sliders():
	merge_slider_x.quantize(int(current_input_tile_size.x / 2))
	merge_slider_y.quantize(int(current_input_tile_size.y / 2))
	overlap_slider_x.quantize(int(current_input_tile_size.x / 2))
	overlap_slider_y.quantize(int(current_input_tile_size.y / 2))
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	merge_slider_x.value = tile.merge_level.x
	merge_slider_y.value = tile.merge_level.y
	overlap_slider_x.value = tile.overlap_level.x
	overlap_slider_y.value = tile.overlap_level.y


func change_part_highlight(part_id: int, is_on: bool):
	texture_container.set_part_highlight(part_id, is_on)


func populate_texture_option():
	var scan_func: FuncRef = funcref(Helpers, "scan_for_textures_in_dir")
	Helpers.populate_project_file_option(texture_option, State.current_dir, 
		scan_func, current_texture_path)


func _on_TextureFileName_item_selected(index: int):
	current_texture_path = texture_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_TEXTURE, current_texture_path)
	if current_texture_path.empty():
		clear()
	else:
		var tile: TPTile = State.get_current_tile()
		if tile == null:
			return
		load_texture(tile.loaded_texture)


func _on_TextureDialogButton_pressed():
	$AddTextureFileDialog.popup_centered()


func _on_AddTextureFileDialog_about_to_show():
	State.popup_started($AddTextureFileDialog)


func _on_AddTextureFileDialog_popup_hide():
	State.popup_ended()


func _on_AddTextureFileDialog_file_selected(path: String):
	if not Helpers.ensure_directory_exists(State.current_dir, Const.TEXTURE_DIR):
		State.report_error("Error: Creating directory \"/%s/\" error" % Const.TEXTURE_DIR)
		return
	var new_texture_path: String = State.current_dir + "/" + Const.TEXTURE_DIR + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_texture_path)
	if error != OK:
		State.report_error("Error: Copy file error number %d." % error)
	current_texture_path = new_texture_path
	populate_texture_option()
	State.update_tile_param(TPTile.PARAM_TEXTURE, current_texture_path)
	load_texture(State.get_current_tile().loaded_texture)


func _on_ScalableTextureContainer_tile_size_changed(size: Vector2):
	current_input_tile_size = size
	State.update_tile_param(TPTile.PARAM_INPUT_SIZE, current_input_tile_size)
	setup_sliders()
	populate_frame_control()


func _on_RateSlider_released(value: float):
	State.update_tile_param(TPTile.PARAM_MERGE, Vector2(value, value))


func _on_OverlapSlider_released(value: float):
	State.update_tile_param(TPTile.PARAM_OVERLAP, Vector2(value, value))


func _on_Smoothing_toggled(button_pressed: bool):
	State.update_tile_param(TPTile.PARAM_SMOOTHING, button_pressed)


func _on_RandomCheckButton_toggled(button_pressed: bool):
	random_seed_edit.editable = button_pressed
	random_seed_apply.disabled = not button_pressed
	State.update_tile_param(TPTile.PARAM_RANDOM_SEED_ENABLED, button_pressed)


func _on_SeedButton_pressed():
	_on_SeedLineEdit_text_entered(random_seed_edit.text)


func _on_SeedLineEdit_text_entered(new_text: String):
	var current_seed = int(new_text)
	State.update_tile_param(TPTile.PARAM_RANDOM_SEED_VALUE, current_seed)


func _on_OutpuResizeButton_toggled(button_pressed: bool):
	State.update_tile_param(TPTile.PARAM_OUTPUT_RESIZE, button_pressed)
	output_tile_size_x.editable = button_pressed
	# the following writes output size along with resize toggle value
#	var x_size := output_tile_size_x.value
#	print(x_size)
#	State.update_tile_param(TPTile.PARAM_OUTPUT_SIZE, Vector2(x_size, x_size), false)


func _on_ResizeSpinBoxX_value_changed(value: float):
	State.update_tile_param(TPTile.PARAM_OUTPUT_SIZE, Vector2(value, value))


func _on_SpacingXSpinBox_value_changed(value: float):
#	var y_spacing := subtile_spacing_y.value
	var y_spacing := value
	State.update_tile_param(TPTile.PARAM_SUBTILE_SPACING, Vector2(value, y_spacing))


func _on_SpacingYSpinBox_value_changed(value):
	var x_spacing := subtile_spacing_x.value
	State.update_tile_param(TPTile.PARAM_SUBTILE_SPACING, Vector2(x_spacing, value))


func reload_tile():
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	tile.reload()


func _on_ReloadButton_pressed():
	reload_tile()
	

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.scancode == KEY_F5:
		if visible:
			get_tree().set_input_as_handled()
			reload_tile()
