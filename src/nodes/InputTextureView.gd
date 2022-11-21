class_name InputTextureView
extends VBoxContainer


var current_texture_path := ""
var current_input_tile_size := Vector2.ZERO

onready var texture_option := $HeaderContainer/TextureOption
onready var texture_container: ScalableTextureContainer = $HBox/ScalableTextureContainer
onready var settings_container := $HBox/SettingsContainer
onready var settings_scroll := $HBox/SettingsContainer/ScrollContainer
onready var settings_vbox := settings_scroll.get_node("VBox")
onready var merge_slider_x: AdvancedSlider = settings_vbox.get_node("Composition/MergeContainer/MergeXSliderContainer/MergeSliderX")
onready var merge_slider_y: AdvancedSlider = settings_vbox.get_node("Composition/MergeContainer/MergeYSliderContainer/MergeSliderY")
onready var overlap_slider_x: AdvancedSlider = settings_vbox.get_node("Composition/OverlapContainer/OverlapXSliderContainer/OverlapSliderX")
onready var overlap_slider_y: AdvancedSlider = settings_vbox.get_node("Composition/OverlapContainer/OverlapYSliderContainer/OverlapSliderY")
onready var output_resize: CheckButton = settings_vbox.get_node("OutputSize/OutputResize/OutpuResizeButton")
onready var output_tile_size_x: AdvancedSpinBox = settings_vbox.get_node("OutputSize/OutputResize/ResizeSpinBoxX")
onready var subtile_spacing_x: AdvancedSpinBox = settings_vbox.get_node("OutputSize/SubtileSpacing/SpacingXSpinBox")
#onready var subtile_spacing_y: AdvancedSpinBox = settings_vbox.get_node("OutputSize/SubtileSpacing/SpacingYSpinBox")
onready var smoothing_enabled: CheckButton = settings_vbox.get_node("OutputSize/SmoothingContainer/Smoothing")
onready var random_seed_enabled: CheckButton = settings_vbox.get_node("Randomization/SeedContainer/RandomCheckButton")
onready var random_seed_edit: LineEdit = settings_vbox.get_node("Randomization/SeedContainer/SeedLineEdit")
onready var random_seed_apply: Button = settings_vbox.get_node("Randomization/SeedContainer/SeedButton")
onready var frames_container := settings_vbox.get_node("Randomization/PartSetupContainer/FramesContainer")
onready var frames_spinbox: AdvancedSpinBox = settings_vbox.get_node("Randomization/FramesSetupContainer/FramesSpinBox")

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
	output_tile_size_x.set_value_quietly(tile.output_tile_size.x)
	subtile_spacing_x.set_value_quietly(tile.subtile_spacing.x)	
	smoothing_enabled.pressed = tile.smoothing
	random_seed_enabled.pressed = tile.random_seed_enabled
	random_seed_edit.text = str(tile.random_seed_value)
	frames_spinbox.set_value_quietly(tile.frames)
	populate_frame_control() # TODO: fix, called 3 times instead of 1


func populate_frame_control():
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	clear_frames()
	var first_frame: FramePartsContainer = frames_container.get_child(0)
	if tile.loaded_ruleset == null:
		return
	var is_scroll_bottom: bool = settings_scroll.scroll_vertical == \
			(settings_scroll.get_node("VBox").rect_size.y - settings_container.rect_size.y)
	first_frame.populate_from_tile(tile)
	for i in range(1, tile.frames):
#		print("variant ", i)
		var new_frame_container: FramePartsContainer = preload("res://src/nodes/FramePartsContainer.tscn").instance()
		new_frame_container.populate_from_tile(tile, i + 1)
		frames_container.add_child(new_frame_container)

	if is_scroll_bottom:
		yield(VisualServer, "frame_post_draw")
		settings_scroll.scroll_vertical = settings_scroll.get_node("VBox").rect_size.y


func on_part_frequency_edit_start(part: PartFrameControl):
	print("EDIT frequency")


func clear_frames():
	var first_frame: FramePartsContainer = frames_container.get_child(0)
	for parts_container in frames_container.get_children():
		parts_container.clear()
		if parts_container != first_frame:
			parts_container.queue_free()


func clear():
	texture_option.selected = texture_option.get_item_count() - 1
#	texture_container.set_main_texture(null)
	texture_container.clear()
	clear_frames()


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


func _on_FramesSpinBox_value_changed_no_silence(value):
	State.update_tile_param(TPTile.PARAM_FRAMES, int(value))
	populate_frame_control()


#func _on_FramesSpinBox_value_changed(value):
#	print("fvekgl")
