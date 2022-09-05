class_name InputTextureView
extends VBoxContainer


var current_texture_path := ""
var current_input_tile_size := Const.DEFAULT_TILE_SIZE

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
onready var smoothing_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/Effects/SmoothingContainer/Smoothing
onready var random_ssed_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/RandomCheckButton
onready var random_seed_edit: LineEdit = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/SeedLineEdit
onready var random_seed_apply: Button = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/SeedButton


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
	random_ssed_enabled.pressed = tile.random_seed_enabled
	random_seed_edit.text = str(tile.random_seed_value)


func clear():
	texture_option.selected = texture_option.get_item_count() - 1
	texture_container.set_main_texture(null)


func load_texture(texture: Texture):
	texture_container.set_main_texture(texture, current_input_tile_size)


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
	var new_texture_path: String = State.current_dir + "/" + path.get_file()
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
