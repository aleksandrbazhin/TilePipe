extends Control

signal input_image_processed()

onready var texture_file_dialog: FileDialog = $TextureDialog
onready var template_file_dialog: FileDialog = $TemplateDialog
onready var save_file_dialog: FileDialog = $SaveTextureDialog
onready var save_resource_dialog: FileDialog = $SaveTextureResourceDialog

onready var texture_in: TextureRect = $Panel/HBox/Images/InContainer/VBoxInput/Control/InputTextureRect
onready var texture_input_bg: TextureRect = $Panel/HBox/Images/InContainer/VBoxInput/Control/BGTextureRect
onready var generation_type_select: OptionButton = $Panel/HBox/Images/InContainer/VBoxInput/InputType
onready var color_process_select: OptionButton = $Panel/HBox/Images/InContainer/VBoxInput/ColorProcessType

onready var corners_merge_container: VBoxContainer = $Panel/HBox/Images/InContainer/MarginContainer/CornersMergeSettings
onready var corners_merge_type_select: OptionButton = corners_merge_container.get_node("CornersOptionButton")
onready var overlay_merge_container: VBoxContainer = $Panel/HBox/Images/InContainer/MarginContainer/OverlaySettings
onready var overlay_merge_type_select: OptionButton = overlay_merge_container.get_node("OverlayOptionButton")

onready var slice_viewport: Viewport = $Panel/HBox/Images/InContainer/VBoxViewport/ViewportContainer/Viewport
onready var texture_in_viewport: TextureRect = slice_viewport.get_node("TextureRect")
onready var slice_slider: HSlider = $Panel/HBox/Images/InContainer/VBoxViewport/HBoxContainer/HSlider

onready var debug_input_control: Control = $Panel/HBox/Images/InContainer/DebugTextureContainer/Control
onready var debug_input_texture: TextureRect = debug_input_control.get_node("DebugTexture")
onready var debug_input_texture_bg: TextureRect = debug_input_control.get_node("BGTextureRect")

onready var template_load_button : Button = $Panel/HBox/Images/TemplateContainer/ButtonBox/TemplateButton
onready var template_type_select: OptionButton = $Panel/HBox/Images/TemplateContainer/ButtonBox/TemplateOption
onready var template_texture: TextureRect = $Panel/HBox/Images/TemplateContainer/ScrollContainer/TemplateTextureRect

onready var output_scroll: ScrollContainer = $Panel/HBox/Images/OutputContainer/ScrollContainer
onready var output_control: Control = output_scroll.get_node("Control")
onready var out_texture: TextureRect = output_scroll.get_node("Control/OutTextureRect")
onready var out_bg_texture: TextureRect = output_scroll.get_node("Control/BGTextureRect")

onready var output_size_select: OptionButton = $Panel/HBox/Settings/SizeOptionButton
onready var export_type_select: CheckButton = $Panel/HBox/Settings/Resourse/AutotileSelect
onready var description_select_box: HBoxContainer = $Panel/HBox/Settings/DescriptionResourse
onready var export_manual_resource_type_select: CheckButton = $Panel/HBox/Settings/DescriptionResourse/Select

var generation_preset: GenerationData


var template_size: Vector2
# input slice = {
#	0: {0: {false: Image, true: Image}, 2: , 4: , 6:}
#	1: ... }
var input_slices: Dictionary = {}
var input_overlayed: Dictionary = {}
# tile_masks = [{"mask": int, "godot_mask": int, "position" Vector2}, ...]
var tile_masks: Array = []

func _ready():
#	save_settings(true) # uncomment on change of save file structure
	
#	print(get_allowed_mask_rotations(16, 5, 21))
#	print(get_allowed_mask_rotations(0,  
#		MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"] | MY_MASK["RIGHT"] | MY_MASK["BOTTOM_RIGHT"],
#	 16))
	connect("input_image_processed", self, "make_output_texture")
	output_size_select.clear()
	for size in Const.OUTPUT_SIZES:
		output_size_select.add_item(Const.OUTPUT_SIZES[size])
	for type in Const.COLOR_PROCESS_TYPES:
		color_process_select.add_item(Const.COLOR_PROCESS_TYPE_NAMES[Const.COLOR_PROCESS_TYPES[type]])
	for type in Const.INPUT_TYPES:
		generation_type_select.add_item(Const.INPUT_TYPE_NAMES[Const.INPUT_TYPES[type]])
	setup_input_type(Const.DEFAULT_INPUT_TYPE)
	for type in Const.TEMPLATE_TYPES:
		template_type_select.add_item(Const.TEMPLATE_TYPE_NAMES[Const.TEMPLATE_TYPES[type]])
	for index in Const.CORNERS_INPUT_PRESETS:
		corners_merge_type_select.add_item(Const.CORNERS_INPUT_PRESETS_NAMES[Const.CORNERS_INPUT_PRESETS[index]])
	for index in Const.OVERLAY_INPUT_PRESETS:
		overlay_merge_type_select.add_item(Const.OVERLAY_INPUT_PRESET_NAMES[Const.OVERLAY_INPUT_PRESETS[index]])
	load_settings()
	generate_tile_masks()
	preprocess_input_image()

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_CloseButton_pressed()

func get_setting_values(load_defaluts: bool = false) -> Dictionary:
	if load_defaluts:
		return Const.DEFAULT_SETTINGS
	else:
		return {
		"last_texture_path": texture_file_dialog.current_path,
		"last_gen_preset_path": texture_file_dialog.current_path.replace(".png", ".json"), # FIX
#		"last_texture_path": texture_file_dialog.current_path.replace(".png", ".json"),
		"last_template_path": template_file_dialog.current_path,
		"last_save_texture_path": save_file_dialog.current_path,
		"last_save_texture_resource_path": save_resource_dialog.current_path,
		"output_tile_size": get_output_tile_size(),
	}

func save_settings(store_defaults: bool = false):
	var save = File.new()
	save.open(Const.SETTINGS_PATH, File.WRITE)
	var data := get_setting_values(store_defaults) 
	save.store_line(to_json(data))
	save.close()

func apply_settings(data: Dictionary):
	texture_file_dialog.current_path = data["last_texture_path"]
	texture_in.texture = load_image_texture(data["last_texture_path"])
	generation_preset = GenerationData.new(data["last_gen_preset_path"])
	template_file_dialog.current_path = data["last_template_path"]
	template_texture.texture = load_image_texture(data["last_template_path"])
	save_file_dialog.current_path = data["last_save_texture_path"]
	save_resource_dialog.current_path = data["last_save_texture_resource_path"]
	output_size_select.selected = Const.OUTPUT_SIZES.keys().find(int(data["output_tile_size"]))
	

func setting_exist() -> bool:
	var save = File.new()
	return save.file_exists(Const.SETTINGS_PATH)

func load_settings():
	if not setting_exist():
		save_settings(true)
	var save = File.new()
	save.open(Const.SETTINGS_PATH, File.READ)
	var save_data: Dictionary = parse_json(save.get_line())
	apply_settings(save_data)
	save.close()

func check_input_texture() -> bool:
	if not is_instance_valid(texture_in.texture):
		return false
	return true

func check_template_texture() -> bool:
	if not is_instance_valid(template_texture.texture):
		return false
	var template_image_size: Vector2 = template_texture.texture.get_data().get_size()
	if template_image_size.x < Const.TEMPLATE_TILE_SIZE and template_image_size.y < Const.TEMPLATE_TILE_SIZE:
		return false
	return true

func compute_template_size() -> Vector2:
	var template_image: Image = template_texture.texture.get_data()
	return template_image.get_size() / Const.TEMPLATE_TILE_SIZE

func get_template_mask_value(template_image: Image, x: int, y: int, 
		mask_check_points: Dictionary = Const.TEMPLATE_MASK_CHECK_POINTS) -> int:
	var mask_value: int = 0
	template_image.lock()
	for mask in mask_check_points:
		var pixel_x: int = x * Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].x
		var pixel_y: int = y *Const.TEMPLATE_TILE_SIZE + mask_check_points[mask].y
		if not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white):
			mask_value += mask
	template_image.unlock()
	return mask_value

func clear_generation_mask():
	tile_masks = []
	for label in template_texture.get_children():
		label.queue_free()
	
func generate_tile_masks():
	clear_generation_mask()
	if not check_template_texture():
		print("WRONG template texture")
		return
	template_size = compute_template_size()
	var template_image: Image = template_texture.texture.get_data()
	for x in range(template_size.x):
		for y in range(template_size.y):
			var mask_value: int = get_template_mask_value(template_image, x, y) 
			var godot_mask_value: int = get_template_mask_value(template_image, x, y, Const.GODOT_MASK_CHECK_POINTS)
			tile_masks.append({"mask": mask_value, "position": Vector2(x, y), "godot_mask": godot_mask_value })
			var mask_text_label := Label.new()
			mask_text_label.add_color_override("font_color", Color(0, 0.05, 0.1))
			mask_text_label.text = str(godot_mask_value)
			mask_text_label.rect_position = Vector2(x, y) * Const.TEMPLATE_TILE_SIZE + Vector2(5, 5)
			template_texture.add_child(mask_text_label)

func put_to_viewport(slice: Image, rotation_key: int, color_process: int,
		is_flipped := false):
	var flip_x := false
	var flip_y := false
	if is_flipped:
		if rotation_key in Const.FLIP_HORIZONTAL_KEYS:
			flip_x = true
		else:
			flip_y = true
	var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_key]['angle']
	var itex = ImageTexture.new()
	itex.create_from_image(slice)
	texture_in_viewport.texture = itex
	texture_in_viewport.material.set_shader_param("rotation", -rotation_angle)
	texture_in_viewport.material.set_shader_param("is_flipped_x", flip_x)
	texture_in_viewport.material.set_shader_param("is_flipped_y", flip_y)
	var is_flow_map: bool = color_process == Const.COLOR_PROCESS_TYPES.FLOW_MAP
	texture_in_viewport.material.set_shader_param("is_flow_map", is_flow_map)

func get_from_viewport(image_fmt: int, resize_factor: float = 1.0) -> Image:
	var image := Image.new()
	var size: Vector2 = texture_in_viewport.texture.get_size()
	image.create(int(size.x), int(size.y), false, image_fmt)
	image.blit_rect(
		slice_viewport.get_texture().get_data(),
		Rect2(Vector2.ZERO, size), 
		Vector2.ZERO)
	if resize_factor != 1.0:
		image.resize(int(size.x * resize_factor), int(size.y * resize_factor))
	return image

func get_color_process() -> int:
	return color_process_select.selected

# TODO: remake - set offsets from corners data in ui for each corner
# for now it only puts every corner slice to top left
# invert for 3 slice
func get_input_flip(index: int, flip: bool) -> bool:
	return flip if index != 3 else not flip

func append_to_debug_image(debug_image: Image, slice_image: Image, slice_size: int, slice_position: Vector2):
	debug_image.blit_rect(
		slice_image,
		Rect2(0, 0, slice_size, slice_size), 
		slice_position
	)
	var itex = ImageTexture.new()
	itex.create_from_image(debug_image)
	debug_input_texture.texture = itex

func generate_corner_slices():
	input_slices = {}
	var output_tile_size: int = get_output_tile_size()
	var input_image: Image = texture_in.texture.get_data()
	var input_slice_size: int = int(input_image.get_size().y)
	var output_slice_size: int = int(output_tile_size / 2.0)
	var resize_factor: float = float(output_slice_size) / float(input_slice_size)
	var new_viewport_size := Vector2(input_slice_size, input_slice_size)
	if slice_viewport.size != new_viewport_size:
		slice_viewport.size = new_viewport_size
		texture_in_viewport.rect_size = new_viewport_size
	var image_input_fmt: int = input_image.get_format()
	var image_fmt: int = slice_viewport.get_texture().get_data().get_format()
	var debug_image := Image.new()
	var color_process: int = get_color_process()
	var debug_texture_size: Vector2 = get_debug_image_rect_size(Const.INPUT_TYPES.CORNERS)
	debug_image.create(int(debug_texture_size.x), int(debug_texture_size.y), false, image_fmt)
	for x in range(generation_preset.get_min_input_size().x):
		input_slices[x] = {}
		var slice := Image.new()
		slice.create(input_slice_size, input_slice_size, false, image_input_fmt)
		slice.blit_rect(input_image, Rect2(x * input_slice_size, 0, input_slice_size, input_slice_size), Vector2.ZERO)
		for rot_index in Const.ROTATION_SHIFTS.size():
			var rotation_key: int = Const.ROTATION_SHIFTS.keys()[rot_index]
			put_to_viewport(slice, rotation_key, color_process, get_input_flip(x, false))
			yield(VisualServer, 'frame_post_draw')
			var processed_slice: Image = get_from_viewport(image_fmt, resize_factor)
			append_to_debug_image(debug_image, processed_slice, output_slice_size, 
				Vector2(x * output_slice_size, 2 * rot_index * output_slice_size))
			put_to_viewport(slice, rotation_key, color_process, get_input_flip(x, true))
			yield(VisualServer, 'frame_post_draw')
			var processed_flipped_slice : Image = get_from_viewport(image_fmt, resize_factor)
			append_to_debug_image(debug_image, processed_slice, output_slice_size, 
				Vector2(x * output_slice_size, (2 * rot_index + 1) * output_slice_size))
			input_slices[x][rotation_key] = {
				false: processed_slice, 
				true: processed_flipped_slice
			}
	texture_in_viewport.hide()
	emit_signal("input_image_processed")

func generate_overlayed_tiles():
	input_slices = {}
	emit_signal("input_image_processed")

func preprocess_input_image():
	texture_in_viewport.show()
	if not check_input_texture():
		print("WRONG input texture")
		return
	debug_input_texture.texture = null
	var generation_type: int = generation_type_select.selected
	match generation_type:
		Const.INPUT_TYPES.CORNERS:
			generate_corner_slices()
		Const.INPUT_TYPES.OVERLAY:
			generate_overlayed_tiles()

func get_output_tile_size() -> int:
	return Const.OUTPUT_SIZES.keys()[output_size_select.selected]

func make_from_corners():
	if input_slices.size() == 0:
		set_output_texture(null)
		return
	var tile_size: int = get_output_tile_size()
	# warning-ignore:integer_division
	var slice_size: int = int(tile_size) / 2
	var image_fmt: int = input_slices[0][0][true].get_format()
	var slice_rect := Rect2(0, 0, slice_size, slice_size)
	var out_image := Image.new()
	out_image.create(tile_size * int(template_size.x), tile_size * int(template_size.y), false, image_fmt)
	var preset: Array = generation_preset.get_preset()
	for mask in tile_masks:
		var tile_position: Vector2 = mask['position'] * tile_size
		if mask["godot_mask"] != 0: # don't draw only center
			
			for in_out_mask in preset:
				var allowed_rotations: Array = get_allowed_mask_rotations(
						in_out_mask["in_mask"]["positive"], 
						in_out_mask["in_mask"]["negative"], mask['mask'])
				for rotation in allowed_rotations:
					var out_tile = in_out_mask["out_tile"]
					var is_flipped: bool = out_tile["flip"]
					var slice_index: int = out_tile["index"]
					var slice_image: Image = input_slices[slice_index][rotation][is_flipped]
					var intile_offset : Vector2 = Const.ROTATION_SHIFTS[rotation]["vector"] * slice_size
					if is_flipped: 
						intile_offset = Const.ROTATION_SHIFTS[rotate_clockwise(rotation)]["vector"] * slice_size
					out_image.blit_rect(slice_image, slice_rect, tile_position + intile_offset)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image)
	set_output_texture(itex)

func set_output_texture(texture: Texture):
	out_texture.texture = texture
	if texture != null:
		var image_size: Vector2 = out_texture.texture.get_data().get_size()
		out_texture.rect_size = image_size
		output_control.rect_min_size = image_size
	else:
		output_control.rect_min_size = Vector2.ZERO


func make_from_overlayed():
	if input_overlayed.size() == 0:
		set_output_texture(null)
		return

func make_output_texture():
	var generation_type: int = generation_type_select.selected
	set_output_texture(null)
	match generation_type:
		Const.INPUT_TYPES.CORNERS:
			make_from_corners()
		Const.INPUT_TYPES.OVERLAY:
			make_from_overlayed()
	
func rotate_clockwise(in_rot: int) -> int:
	var out: int = int(clamp(in_rot, 0, 6)) - 2
	if out == -2:
		out = 6
	return out

func rotate_check_mask(mask: int, rot: int) -> int:
	var rotated_check: int = mask << rot
	if rotated_check > 255:
		var overshoot: int = rotated_check >> 8
		rotated_check ^= overshoot << 8
		rotated_check |= overshoot
	return rotated_check

# returns all rotations for mask which satisfy both templates
#func check_mask_template(pos_check_mask: int, neg_check_mask: int, current_mask: int) -> Array:
func get_allowed_mask_rotations(pos_check_mask: int, neg_check_mask: int, current_mask: int) -> Array:
	var rotations: Array = []
	for rotation in Const.ROTATION_SHIFTS:
		var rotated_check: int = rotate_check_mask(pos_check_mask, rotation)
		var satisfies_check := false
		if current_mask & rotated_check == rotated_check:
			satisfies_check = true
		if satisfies_check and neg_check_mask != 0: # check negative mask
			rotated_check = rotate_check_mask(neg_check_mask, rotation)
			var inverted_check: int = (~rotated_check & 0xFF)
#			print("%s: %s %s %s" % [str(rotation), str(rotated_check), 
#				str(inverted_check),
#				str(current_mask & inverted_check)])
			if current_mask | inverted_check != inverted_check:
				satisfies_check = false
		if satisfies_check:
			rotations.append(rotation)
	return rotations

func _on_CloseButton_pressed():
	tile_masks.empty()
	get_tree().quit()

func _on_Save_pressed():
	save_file_dialog.popup_centered()

func _on_Save2_pressed():
	save_resource_dialog.popup_centered()

func load_image_texture(path: String) -> Texture:
	if path.begins_with("res://"):
		var texture: Texture = load(path)
		return texture
	else:
		var image = Image.new()
		var err = image.load(path)
		if(err != 0):
			print("Error loading the image: " + path)
			return null
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	
func _on_TextureDialog_file_selected(path):
	texture_in.texture = load_image_texture(path)
	preprocess_input_image()
	save_settings()

func _on_TemplateDialog_file_selected(path):
	template_texture.texture = load_image_texture(path)
	generate_tile_masks()
	make_output_texture()
	save_settings()

func _on_TemplateButton_pressed():
	template_file_dialog.popup_centered()

func _on_Button_pressed():
	texture_file_dialog.popup_centered()

func save_texture_png(path: String):
	out_texture.texture.get_data().save_png(path)

func _on_SaveTextureDialog_file_selected(path):
	save_texture_png(path)
	save_settings()

func _on_SaveTextureDialog2_file_selected(path: String):
	save_texture_png(path)
	var resource_exporter: GodotExporter = GodotExporter.new()
	resource_exporter.save_resource(path, get_output_tile_size(), tile_masks,
		export_type_select.pressed, 
		out_texture.texture.get_data().get_size(),
		export_manual_resource_type_select.pressed
	)
	save_settings()

func _on_AutotileSelect_toggled(button_pressed):
	description_select_box.visible = not button_pressed

func setup_input_type(index: int):
	match index:
		Const.INPUT_TYPES.CORNERS:
			overlay_merge_container.hide()
			corners_merge_container.show()
			color_process_select.disabled = true
			color_process_select.selected = Const.COLOR_PROCESS_TYPES.NO
		Const.INPUT_TYPES.OVERLAY:
			corners_merge_container.hide()
			overlay_merge_container.show()
			color_process_select.disabled = false

func _on_InputType_item_selected(index):
	setup_input_type(index)
	preprocess_input_image()

func _on_ColorProcessType_item_selected(index):
	preprocess_input_image()

func _on_ReloadButton_pressed():
	preprocess_input_image()

func _on_TemplateOption_item_selected(index):
	if index == Const.TEMPLATE_TYPES.CUSTOM:
		template_load_button.disabled = false
		template_texture.texture = null
		template_texture.rect_size = Vector2.ZERO
		output_scroll.get_v_scrollbar().rect_size.x = 0
		output_scroll.get_v_scrollbar().rect_size.y = 0
		clear_generation_mask()
	else:
		template_load_button.disabled = true
		template_texture.texture = load_image_texture(Const.TEMPLATE_PATHS[index])
		generate_tile_masks()
	make_output_texture()
	save_settings()

func _on_CornersOptionButton_item_selected(index):
	preprocess_input_image()

func _on_OverlayOptionButton_item_selected(index):
	preprocess_input_image()

func get_debug_image_rect_size(input_type: int) -> Vector2:
	var output_tile_size: int = get_output_tile_size()
	var size := Vector2.ZERO
	match input_type:
		Const.INPUT_TYPES.CORNERS:
			# warning-ignore:integer_division
			var slice_size: int = output_tile_size / 2
			var min_size: Vector2 = generation_preset.get_min_input_size()
			size.x = slice_size * min_size.x
			size.y = slice_size * min_size.y * 8
		Const.INPUT_TYPES.OVERLAY:
			pass
	return size

func _on_SizeOptionButton_item_selected(index):
	var output_scale_factor: float = float(get_output_tile_size()) / float(Const.DEFAULT_OUTPUT_SIZE)
	var output_scale := Vector2(output_scale_factor, output_scale_factor)
	out_bg_texture.rect_scale = output_scale
	out_bg_texture.rect_size = output_control.rect_size / output_scale_factor
	debug_input_control.rect_min_size = get_debug_image_rect_size(Const.INPUT_TYPES.CORNERS)
	print(debug_input_control.rect_min_size)
	debug_input_texture_bg.rect_scale = output_scale
	debug_input_texture_bg.rect_size = debug_input_control.rect_size / output_scale_factor
	preprocess_input_image()
	save_settings()


