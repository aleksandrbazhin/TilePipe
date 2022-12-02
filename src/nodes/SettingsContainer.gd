class_name SettingsContainer
extends PanelContainer


onready var settings_scroll := $ScrollContainer
onready var settings_vbox := settings_scroll.get_node("VBox")
onready var merge_slider_x: AdvancedSlider = settings_vbox.get_node("Composition/MergeContainer/MergeXSliderContainer/MergeSliderX")
onready var merge_slider_y: AdvancedSlider = settings_vbox.get_node("Composition/MergeContainer/MergeYSliderContainer/MergeSliderY")
onready var overlap_slider_x: AdvancedSlider = settings_vbox.get_node("Composition/OverlapContainer/OverlapXSliderContainer/OverlapSliderX")
onready var overlap_slider_y: AdvancedSlider = settings_vbox.get_node("Composition/OverlapContainer/OverlapYSliderContainer/OverlapSliderY")
onready var output_resize: AdvancedCheckButton = settings_vbox.get_node("OutputSize/OutputResize/OutpuResizeButton")
onready var output_tile_size_x: AdvancedSpinBox = settings_vbox.get_node("OutputSize/OutputResize/ResizeSpinBoxX")
onready var subtile_spacing_x: AdvancedSpinBox = settings_vbox.get_node("OutputSize/SubtileSpacing/SpacingXSpinBox")
#onready var subtile_spacing_y: AdvancedSpinBox = settings_vbox.get_node("OutputSize/SubtileSpacing/SpacingYSpinBox")
onready var smoothing_enabled: AdvancedCheckButton = settings_vbox.get_node("OutputSize/SmoothingContainer/Smoothing")
onready var random_seed_enabled: AdvancedCheckButton = settings_vbox.get_node("Randomization/SeedContainer/SeedCheckButton")
onready var random_seed_edit: AdvancedLineEdit = settings_vbox.get_node("Randomization/SeedContainer/SeedLineEdit")
onready var random_seed_apply: Button = settings_vbox.get_node("Randomization/SeedContainer/SeedButton")
onready var frames_container := settings_vbox.get_node("Randomization/PartSetupContainer/FramesContainer")
onready var frames_spinbox: AdvancedSpinBox = settings_vbox.get_node("Randomization/FramesSetupContainer/FramesSpinBox")


func load_data(tile: TPTile):
	setup_sliders(tile.input_tile_size)
	output_resize.set_toggled_quietly(tile.output_resize)
	output_tile_size_x.editable = tile.output_resize
	output_tile_size_x.set_value_quietly(tile.output_tile_size.x)
	subtile_spacing_x.set_value_quietly(tile.subtile_spacing.x)
	smoothing_enabled.set_toggled_quietly(tile.smoothing)
	random_seed_enabled.set_toggled_quietly(tile.random_seed_enabled)
	random_seed_edit.editable = tile.random_seed_enabled
	random_seed_apply.disabled = not tile.random_seed_enabled
	random_seed_edit.set_text_quietly(str(tile.random_seed_value))
	frames_spinbox.set_value_quietly(tile.frame_number)
	populate_frame_control() # TODO: fix, called 3 times instead of 1


func setup_sliders(current_input_tile_size: Vector2):
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


func clear():
	clear_frames()
	

func clear_frames():
	var first_frame: FramePartsContainer = frames_container.get_child(0)
	for parts_container in frames_container.get_children():
		parts_container.clear()
		if parts_container != first_frame:
			parts_container.queue_free()


func populate_frame_control():
	print()
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	clear_frames()
	var first_frame: FramePartsContainer = frames_container.get_child(0)
	if tile.ruleset == null:
		return
	var is_scroll_bottom: bool = settings_scroll.scroll_vertical == \
			(settings_scroll.get_node("VBox").rect_size.y - self.rect_size.y)
	first_frame.populate_from_tile(tile, 0)
	for i in range(1, tile.frame_number):
		var new_frame_container: FramePartsContainer = preload("res://src/nodes/FramePartsContainer.tscn").instance()
		new_frame_container.populate_from_tile(tile, i)
		frames_container.add_child(new_frame_container)
	if is_scroll_bottom:
		yield(VisualServer, "frame_post_draw")
		settings_scroll.scroll_vertical = settings_scroll.get_node("VBox").rect_size.y


func _on_MergeSliderX_released(value):
	State.update_tile_param(TPTile.PARAM_MERGE, Vector2(value, value))


func _on_OverlapSliderX_released(value):
	State.update_tile_param(TPTile.PARAM_OVERLAP, Vector2(value, value))


func _on_SeedButton_pressed(is_silenced: bool = false):
	_on_SeedLineEdit_text_changed_no_silence(random_seed_edit.text)


func _on_SeedLineEdit_text_changed_no_silence(new_text: String):
	var current_seed = int(new_text)
	State.update_tile_param(TPTile.PARAM_RANDOM_SEED_VALUE, current_seed)


func _on_SpacingXSpinBox_value_changed_no_silence(value: float):
	var y_spacing := value
	State.update_tile_param(TPTile.PARAM_SUBTILE_SPACING, Vector2(value, y_spacing))


func _on_OutpuResizeButton_toggled_no_silence(button_pressed):
	State.update_tile_param(TPTile.PARAM_OUTPUT_RESIZE, button_pressed)
	output_tile_size_x.editable = button_pressed


func _on_ResizeSpinBoxX_value_changed_no_silence(value):
	State.update_tile_param(TPTile.PARAM_OUTPUT_SIZE, Vector2(value, value))


func _on_Smoothing_toggled_no_silence(button_pressed):
	State.update_tile_param(TPTile.PARAM_SMOOTHING, button_pressed)


func _on_SeedCheckButton_toggled_no_silence(button_pressed):
	random_seed_edit.editable = button_pressed
	random_seed_apply.disabled = not button_pressed
	State.update_tile_param(TPTile.PARAM_RANDOM_SEED_ENABLED, button_pressed)


func _on_FramesSpinBox_value_changed_no_silence(value):
	State.update_tile_param(TPTile.PARAM_FRAME_NUMBER, int(value))
	populate_frame_control()

