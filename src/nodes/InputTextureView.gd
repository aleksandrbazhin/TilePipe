extends VBoxContainer

class_name InputTextureView


var current_texture_path := ""
var current_input_tile_size := Const.DEFAULT_TILE_SIZE

onready var texture_option := $HeaderContainer/TextureOption
onready var texture_container: ScalableTextureContainer = $HBox/ScalableTextureContainer
onready var merge_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeXSliderContainer/RateSlider
onready var merge_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/MergeContainer/MergeYSliderContainer/RateSlider
onready var overlay_slider_x: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapXSliderContainer/OverlapSlider
onready var overlay_slider_y: AdvancedSlider = $HBox/SettingsContainer/ScrollContainer/VBox/Composition/OverlapContainer/OverlapYSliderContainer/OverlapSlider
onready var output_tile_size_option: OptionButton = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/HBoxContainer/SizeOptionButton
onready var subtile_offset: SpinBox = $HBox/SettingsContainer/ScrollContainer/VBox/OutputSize/SubtileOffset/OffsetSpinBox
onready var smoothing_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/Effects/SmoothingContainer/Smoothing
onready var random_ssed_enabled: CheckButton = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/RandomCheckButton
onready var random_seed_edit: LineEdit = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/SeedLineEdit
onready var random_seed_apply: Button = $HBox/SettingsContainer/ScrollContainer/VBox/Randomization/HBoxContainer/SeedButton


func _ready():
	for size_option in Const.OUTPUT_TILE_SIZE_OPTIONS:
		output_tile_size_option.add_item(Const.OUTPUT_TILE_SIZE_OPTIONS[size_option])


func load_data(tile: TileInProject):
	current_texture_path = tile.texture_path
	current_input_tile_size = tile.input_tile_size
	populate_texture_option()
	setup_sliders()
	merge_slider_x.value = tile.merge_level.x
	merge_slider_y.value = tile.merge_level.y
	overlay_slider_x.value = tile.overlap_level.x
	overlay_slider_y.value = tile.overlap_level.y
	if current_texture_path != "":
		load_texture(tile.loaded_texture)
	output_tile_size_option.selected = Helpers.get_closest_output_size_key(tile.output_tile_size)
	subtile_offset.value = tile.subtile_offset.x
	smoothing_enabled.pressed = tile.smoothing
	random_ssed_enabled.pressed = tile.random_seed_enabled
	random_seed_edit.text = str(tile.random_seed_value)


func load_texture(texture: Texture):
	texture_container.set_texture(texture, current_input_tile_size)
	

func setup_sliders():
	merge_slider_x.quantize(int(current_input_tile_size.x / 2))
	merge_slider_y.quantize(int(current_input_tile_size.y / 2))
	overlay_slider_x.quantize(int(current_input_tile_size.x / 2))
	overlay_slider_y.quantize(int(current_input_tile_size.y / 2))


func _on_TextureFileName_item_selected(index: int):
	current_texture_path = texture_option.get_item_metadata(index)
	State.update_tile_param(TileInProject.PARAM_TEXTURE, current_texture_path)
	load_texture(State.current_tile_ref.get_ref().loaded_texture)


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
	State.update_tile_texture(current_texture_path)
	load_texture(State.current_tile_ref.get_ref().loaded_texture)


func populate_texture_option():
	var scan_func: FuncRef = funcref(Helpers, "scan_for_textures_in_dir")
	Helpers.populate_project_file_option(texture_option, State.current_dir, 
		scan_func, current_texture_path)


func _on_ScalableTextureContainer_tile_size_changed(size: Vector2):
	current_input_tile_size = size
	State.update_tile_param(TileInProject.PARAM_INPUT_SIZE, current_input_tile_size)
	setup_sliders()


func _on_RateSlider_released(value: float):
	State.update_tile_param(TileInProject.PARAM_MERGE, Vector2(value, value))


func _on_OverlapSlider_released(value: float):
	State.update_tile_param(TileInProject.PARAM_OVERLAP, Vector2(value, value))


func change_part_highlight(part_id: int, is_on: bool):
	texture_container.set_part_highlight(part_id, is_on)


func _on_Smoothing_toggled(button_pressed: bool):
	State.update_tile_param(TileInProject.PARAM_SMOOTHING, button_pressed)


func _on_SizeOptionButton_item_selected(index: int):
	State.update_tile_param(TileInProject.PARAM_OUTPUT_SIZE, index)


func _on_SetOffsetButton_pressed():
	var offset := int(subtile_offset.value)
	var offset_vec := Vector2(offset, offset)
	State.update_tile_param(TileInProject.PARAM_SUBTILE_OFFSET, offset_vec)


func _on_RandomCheckButton_toggled(button_pressed: bool):
	random_seed_edit.editable = button_pressed
	random_seed_apply.disabled = not button_pressed
	State.update_tile_param(TileInProject.PARAM_RANDOM_SEED_ENABLED, button_pressed)


func _on_SeedButton_pressed():
	_on_SeedLineEdit_text_entered(random_seed_edit.text)


func _on_SeedLineEdit_text_entered(new_text: String):
	var current_seed = int(new_text)
	State.update_tile_param(TileInProject.PARAM_RANDOM_SEED_VALUE, current_seed)
