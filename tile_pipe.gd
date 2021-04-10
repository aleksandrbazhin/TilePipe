extends Control

signal input_image_processed()

#const INPUT_COONTAINER_DEFAULT_SIZE := Vector2(192, 192)

onready var godot_resource_exporter := GodotExporter.new()

onready var texture_file_dialog: FileDialog = $TextureDialog
onready var template_file_dialog: FileDialog = $TemplateDialog
onready var save_file_dialog: FileDialog = $SaveTextureDialog
onready var save_resource_dialog: FileDialog = $SaveTextureResourceDialog
onready var popup_dialog: AcceptDialog = $PopupDialog

onready var input_container: VBoxContainer = $Panel/HBox/Images/InContainer/VBoxInput
onready var texure_input_container: Control = input_container.get_node("Control")
onready var texture_in: TextureRect = texure_input_container.get_node("InputTextureRect")
onready var texture_input_bg: TextureRect = texure_input_container.get_node("BGTextureRect")
onready var generation_type_select: OptionButton = $Panel/HBox/Images/InContainer/VBoxContainer/InputType
onready var example_texture: TextureRect = $Panel/HBox/Images/InContainer/VBoxContainer/ExampleBox/TextureRect

onready var corners_merge_container: VBoxContainer = $Panel/HBox/Images/InContainer/VBoxContainer/CornersMergeSettings
onready var corners_merge_type_select: OptionButton = corners_merge_container.get_node("CornersOptionButton")

onready var settings_container: VBoxContainer = $Panel/HBox/Images/InContainer/VBoxSettings
onready var rand_seed_container: VBoxContainer = settings_container.get_node("RandomContainer")
onready var rand_seed_check: CheckButton = rand_seed_container.get_node("HBoxContainer/RandomCheckButton")
onready var rand_seed_value: LineEdit = rand_seed_container.get_node("LineEdit")

onready var overlay_merge_container: VBoxContainer = $Panel/HBox/Images/InContainer/VBoxContainer/OverlaySettings
onready var overlay_merge_type_select: OptionButton = overlay_merge_container.get_node("OverlayOptionButton")

onready var color_process_select: OptionButton = settings_container.get_node("ColorProcessContainer/ColorProcessType")

onready var debug_input_scroll: Control = $Panel/HBox/Images/InContainer/WorkTextureContainer
onready var debug_input_control: Control = debug_input_scroll.get_node("Control")
onready var debug_input_texture: TextureRect = debug_input_control.get_node("DebugTexture")
onready var debug_input_texture_bg: TextureRect = debug_input_control.get_node("BGTextureRect")

onready var rotate_viewport: Viewport = debug_input_control.get_node("InViewportContainer/Viewport")
onready var rotated_texture_in_viewport: TextureRect = rotate_viewport.get_node("TextureRect")
onready var overlay_viewport: Viewport = debug_input_control.get_node("OverlayViewportContainer/Viewport")
onready var overlay_texture_in_viewport: TextureRect = overlay_viewport.get_node("TextureRect")
onready var overlay_merge_rate_slider: HSlider = settings_container.get_node("HSliderContainer/RateSlider")
onready var overlay_overlap_slider: HSlider = settings_container.get_node("OverlapSliderContainer/OverlapSlider")

onready var template_load_button : Button = $Panel/HBox/Images/TemplateContainer/ButtonBox/TemplateButton
onready var template_type_select: OptionButton = $Panel/HBox/Images/TemplateContainer/ButtonBox/TemplateOption
onready var template_texture: TextureRect = $Panel/HBox/Images/TemplateContainer/ScrollContainer/TemplateTextureRect

onready var output_scroll: ScrollContainer = $Panel/HBox/Images/OutputContainer/ScrollContainer
onready var output_control: Control = output_scroll.get_node("Control")
onready var out_texture: TextureRect = output_control.get_node("OutTextureRect")
onready var out_bg_texture: TextureRect = output_control.get_node("BGTextureRect")

onready var output_settings: VBoxContainer = output_scroll.get_node("Control/OutputControlContainer")
onready var output_size_select: OptionButton = output_settings.get_node("SizeOptionButton")
onready var smoothing_check: CheckButton = output_settings.get_node("SmoothingContainer/Smoothing")


var is_ui_blocked: bool = false
var is_slider_changed: bool = false
var generation_data: GenerationData
var template_size: Vector2
var input_slices: Dictionary = {}
#var input_tile_size_vector := Vector2.ZERO
var input_overlayed_tiles: Array = []
# tile_masks = [{"mask": int, "godot_mask": int, "position" Vector2}, ...]
var tile_masks: Array = []
var rng = RandomNumberGenerator.new()
var last_input_texture_path: String = ""
var last_tile_name: String = ""
var saved_texture_rects: Array = []
var saved_tile_names: Array = []

func _ready():
#	OS.window_maximized = true
#	rand_seed_check.disabled = true
	rng.randomize()
#	save_settings(true) # uncomment on change of save file structure
	connect("input_image_processed", self, "make_output_texture")
	godot_resource_exporter.connect("exporter_error", self, "report_error")
	output_size_select.clear()
	for size in Const.OUTPUT_SIZES:
		output_size_select.add_item(Const.OUTPUT_SIZES[size])
	for type in Const.COLOR_PROCESS_TYPES:
		color_process_select.add_item(Const.COLOR_PROCESS_TYPE_NAMES[Const.COLOR_PROCESS_TYPES[type]])
	for type in Const.INPUT_TYPES:
		generation_type_select.add_item(Const.INPUT_TYPE_NAMES[Const.INPUT_TYPES[type]])
#	setup_input_type(Const.DEFAULT_INPUT_TYPE)
	for type in Const.TEMPLATE_TYPES:
		template_type_select.add_item(Const.TEMPLATE_TYPE_NAMES[Const.TEMPLATE_TYPES[type]])
	for index in Const.CORNERS_INPUT_PRESETS:
		corners_merge_type_select.add_item(Const.CORNERS_INPUT_PRESETS_NAMES[Const.CORNERS_INPUT_PRESETS[index]])
	for index in Const.OVERLAY_INPUT_PRESETS:
		overlay_merge_type_select.add_item(Const.OVERLAY_INPUT_PRESET_NAMES[Const.OVERLAY_INPUT_PRESETS[index]])
	load_settings()
	generate_tile_masks()
	preprocess_input_image()
	
	adjust_for_small_resolution()

func adjust_for_small_resolution():
	if OS.get_screen_size().x < OS.window_size.x:
		settings_container.rect_min_size = Vector2.ZERO
		OS.window_maximized = true
	

func _process(_delta: float):
	
	if Input.is_action_just_pressed("ui_cancel"):
		if texture_file_dialog.visible:
			texture_file_dialog.hide()
		elif template_file_dialog.visible:
			template_file_dialog.hide()
		elif save_file_dialog.visible:
			save_file_dialog.hide()
		elif save_resource_dialog.visible:
			save_resource_dialog.hide()
		elif popup_dialog.visible:
			popup_dialog.hide()
		else:
			exit()

var last_generator_preset_path: String = ""
func get_generator_preset_path() -> String:
	var path: String = ""
	match generation_type_select.selected:
		Const.INPUT_TYPES.CORNERS:
			var corner_preset: int = corners_merge_type_select.selected
			path = Const.CORNERS_INPUT_PRESETS_DATA_PATH[corner_preset]
		Const.INPUT_TYPES.OVERLAY:
			var overlay_preset: int = overlay_merge_type_select.selected
			path = Const.OVERLAY_INPUT_PRESETS_DATA_PATH[overlay_preset]
	return path

func get_default_template() -> String:
	return Const.TEMPLATE_PATHS[Const.TEMPLATE_TYPES.TEMPLATE_47]

var custom_template_path: String = ""
func get_template_path() -> String:
	if custom_template_path != "":
		return custom_template_path
	else:
		return get_default_template()

func capture_setting_values() -> Dictionary:
	return {
		"last_texture_path": last_input_texture_path,
		"last_gen_preset_path": get_generator_preset_path(),
		"last_template_path": get_template_path(),
		"last_save_texture_path": save_file_dialog.current_path,
		"last_save_texture_resource_path": save_resource_dialog.current_path,
		"output_tile_size": get_output_tile_size(),
		"input_type": generation_type_select.selected,
		"corner_preset": corners_merge_type_select.selected,
		"overlay_preset": overlay_merge_type_select.selected,
		"smoothing": smoothing_check.pressed,
		"merge_level": overlay_merge_rate_slider.value,
		"overlap_level": overlay_overlap_slider.value,
		"use_random_seed": rand_seed_check.pressed,
		"random_seed_value": int(rand_seed_value.text)
	}

func save_settings(store_defaults: bool = false):
	var save = File.new()
	save.open(Const.SETTINGS_PATH, File.WRITE)
	var data := Const.DEFAULT_SETTINGS
	if not store_defaults:
		data = capture_setting_values() 
	save.store_line(to_json(data))
	save.close()


func load_input_texture(path: String):
	var loaded_texture: Texture = load_image_texture(path)
	if loaded_texture == null:
		path = generation_data.get_example_path()
		loaded_texture = load_image_texture(path)
	last_input_texture_path = path
	texture_in.texture = loaded_texture
	last_tile_name = path.get_file().split(".")[0]
	output_control.get_node("TileNameLabel").text = last_tile_name

func load_template_texture(path: String):
	var loaded_texture: Texture = load_image_texture(path)
	if loaded_texture == null:
		path = get_default_template()
		loaded_texture = load_image_texture(path)
	custom_template_path = path
	template_texture.texture = loaded_texture

func apply_settings(data: Dictionary):
	generation_data = GenerationData.new(data["last_gen_preset_path"])
	load_input_texture(data["last_texture_path"])
	texture_file_dialog.current_path = data["last_texture_path"]
	load_template_texture(data["last_template_path"])
	template_file_dialog.current_path = data["last_template_path"]
	save_file_dialog.current_path = data["last_save_texture_path"]
	save_resource_dialog.current_path = data["last_save_texture_resource_path"]
	output_size_select.selected = Const.OUTPUT_SIZES.keys().find(int(data["output_tile_size"]))
	generation_type_select.selected = data["input_type"]
	corners_merge_type_select.selected = data["corner_preset"]
	overlay_merge_type_select.selected = data["overlay_preset"]
	smoothing_check.pressed = data["smoothing"]
	overlay_merge_rate_slider.value = data["merge_level"]
	overlay_overlap_slider.value = data["overlap_level"]
	rand_seed_check.pressed = data["use_random_seed"]
	rand_seed_value.text = str(data["random_seed_value"])
	setup_input_type(generation_type_select.selected)
	update_output_bg_texture_scale()
	
func settings_exist() -> bool:
	var save = File.new()
	return save.file_exists(Const.SETTINGS_PATH)

func load_settings():
	if not settings_exist():
		save_settings(true)
	var save = File.new()
	save.open(Const.SETTINGS_PATH, File.READ)
#	print(save.get_line())
	var save_data: Dictionary = parse_json(save.get_line())
	save.close()
	apply_settings(save_data)
	

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

func mark_template_tile(mask_value: int, mask_position: Vector2, is_text: bool = false):
	if is_text:
		var mask_text_label := Label.new()
		mask_text_label.add_color_override("font_color", Color(0, 0.05, 0.1))
		mask_text_label.text = str(mask_value)
		mask_text_label.rect_position = mask_position * Const.TEMPLATE_TILE_SIZE + Vector2(8, 8)
		template_texture.add_child(mask_text_label)
	else:
		for x in range(3):
			for y in range(3):
				var check: int = 1 << (x + y * 3)
				if check & mask_value == check:
					var mask_marker = TextureRect.new()
					mask_marker.rect_position = mask_position * Const.TEMPLATE_TILE_SIZE + \
						Vector2(x * 10.6 + 1, y * 10.6 + 1)
					mask_marker.texture = preload("res://template_marker.png")
					template_texture.add_child(mask_marker)

func generate_tile_masks():
	clear_generation_mask()
	if not check_template_texture():
		report_error("Error: Wrong template texture")
		return
	template_size = compute_template_size()
	var template_image: Image = template_texture.texture.get_data()
	for x in range(template_size.x):
		for y in range(template_size.y):
			var mask_value: int = get_template_mask_value(template_image, x, y) 
			var godot_mask_value: int = get_template_mask_value(template_image, x, y, Const.GODOT_MASK_CHECK_POINTS)
			tile_masks.append({"mask": mask_value, "position": Vector2(x, y), "godot_mask": godot_mask_value })
			mark_template_tile(mask_value, Vector2(x, y), true)
#			mark_template_tile(godot_mask_value, Vector2(x, y), false)

func put_to_rotation_viewport(slice: Image, rotation_key: int, is_flipped := false):
	var flip_x := false
	var flip_y := false
	if is_flipped:
		if rotation_key in Const.FLIP_HORIZONTAL_KEYS:
			flip_x = true
		else:
			flip_y = true
	var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_key]['angle']
	var itex = ImageTexture.new()
	itex.create_from_image(slice, 0)
	rotated_texture_in_viewport.texture = itex
	rotated_texture_in_viewport.material.set_shader_param("rotation", -rotation_angle)
	rotated_texture_in_viewport.material.set_shader_param("is_flipped_x", flip_x)
	rotated_texture_in_viewport.material.set_shader_param("is_flipped_y", flip_y)
	var is_flow_map: bool = get_color_process() == Const.COLOR_PROCESS_TYPES.FLOW_MAP
	rotated_texture_in_viewport.material.set_shader_param("is_flow_map", is_flow_map)

func get_from_rotation_viewport(image_fmt: int, resize_factor: float = 1.0) -> Image:
	var image := Image.new()
	var size: Vector2 = rotated_texture_in_viewport.texture.get_size()
	image.create(int(size.x), int(size.y), false, image_fmt)
	image.blit_rect(
		rotate_viewport.get_texture().get_data(),
		Rect2(Vector2.ZERO, size), 
		Vector2.ZERO)
	if resize_factor != 1.0:
		var interpolation: int = Image.INTERPOLATE_NEAREST if not smoothing_check.pressed else Image.INTERPOLATE_LANCZOS
		image.resize(int(size.x * resize_factor), int(size.y * resize_factor), interpolation)
	return image

func get_color_process() -> int:
	return color_process_select.selected


func append_to_debug_image(debug_image: Image, slice_image: Image, slice_size: int, slice_position: Vector2):
	debug_image.blit_rect(
		slice_image,
		Rect2(0, 0, slice_size, slice_size), 
		slice_position
	)
	var itex = ImageTexture.new()
	itex.create_from_image(debug_image, 0)
	debug_input_texture.texture = itex

# snap to closest bigger power of 2, for less than 1 x returns snapped fraction
func snap_up_to_po2(x: float) -> float:
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x))))
	else:
		return 1.0/float(nearest_po2(int(floor(1.0/x))))

func snap_down_to_po2(x: float) -> float:
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x)))) / 2.0
	else:
		return 1.0/float(nearest_po2(int(ceil(1.0/x))))

func set_input_tile_size(input_tile_size: int, input_image: Image):
#	input_tile_size_vector = Vector2(input_tile_size, input_tile_size)
	var input_size: Vector2 = input_image.get_size()
	var x_scale: float = texure_input_container.rect_size.x / input_size.x
	var y_scale: float = texure_input_container.rect_size.y / input_size.y
	var scale_factor: float = min(x_scale, y_scale)
	scale_factor = snap_down_to_po2(scale_factor)
	texture_in.rect_scale = Vector2(scale_factor, scale_factor)
	var bg_scale = scale_factor * float(input_tile_size) / float(Const.DEFAULT_OUTPUT_SIZE)
	texture_input_bg.rect_size = texure_input_container.rect_size / bg_scale
	texture_input_bg.rect_scale = Vector2(bg_scale, bg_scale)
	texure_input_container.get_node("TileSizeLabel").text = "%sx%s" % [input_tile_size, input_tile_size]

func get_output_tile_size() -> int:
	return Const.OUTPUT_SIZES.keys()[output_size_select.selected]

func get_input_image_random_max_variants() -> int:
	var input_image: Image = texture_in.texture.get_data()
	var min_input_slices: Vector2 = generation_data.get_min_input_size()
	var input_slice_size: int = int(input_image.get_size().x / min_input_slices.x)
	return int(max(1, input_image.get_size().y / input_slice_size))

func setup_randomize_controls(is_enabled: bool):
	if is_enabled:
		if not is_ui_blocked:
			rand_seed_check.disabled = false
		if rand_seed_check.is_in_group("really_disabled"):
			rand_seed_check.remove_from_group("really_disabled")
	else:
		rand_seed_check.add_to_group("really_disabled")
		rand_seed_check.disabled = true
		rand_seed_value.editable = false

func generate_corner_slices():
	input_slices = {}
	var output_tile_size: int = get_output_tile_size()
	var input_image: Image = texture_in.texture.get_data()
	var min_input_slices: Vector2 = generation_data.get_min_input_size()
	var input_slice_size: int = int(input_image.get_size().x / min_input_slices.x)
	set_input_tile_size(input_slice_size * 2, input_image)
	var input_max_random_variants: int = get_input_image_random_max_variants()
	setup_randomize_controls(input_max_random_variants > 1)
	var output_slice_size: int = int(output_tile_size / 2.0)
	var resize_factor: float = float(output_slice_size) / float(input_slice_size)
	var new_viewport_size := Vector2(input_slice_size, input_slice_size)
	if rotate_viewport.size != new_viewport_size:
		rotate_viewport.size = new_viewport_size
		rotated_texture_in_viewport.rect_size = new_viewport_size
#	print(new_viewport_size)
	var image_input_fmt: int = input_image.get_format()
	var image_fmt: int = rotate_viewport.get_texture().get_data().get_format()
	var debug_image := Image.new()
#	var color_process: int = get_color_process()
	var debug_texture_size: Vector2 = get_debug_image_rect_size(Const.INPUT_TYPES.CORNERS)
	debug_image.create(int(debug_texture_size.x * input_max_random_variants), int(debug_texture_size.y), false, image_fmt)
	for x in range(min_input_slices.x):
		input_slices[x] = []
		for random_variant_y in range(input_max_random_variants):
			var slice := Image.new()
			slice.create(input_slice_size, input_slice_size, false, image_input_fmt)
			slice.blit_rect(input_image, Rect2(x * input_slice_size, 
							random_variant_y * input_slice_size, 
							input_slice_size, input_slice_size), Vector2.ZERO)
			var slice_variant_not_empty: bool = true
			if slice_variant_not_empty:
				var slice_variant = {}
				for rot_index in Const.ROTATION_SHIFTS.size():
					var rotation_key: int = Const.ROTATION_SHIFTS.keys()[rot_index]
					put_to_rotation_viewport(slice, rotation_key, false)
					yield(VisualServer, 'frame_post_draw')
					var processed_slice: Image = get_from_rotation_viewport(image_fmt, resize_factor)
					append_to_debug_image(debug_image, processed_slice, output_slice_size, 
						Vector2((x* input_max_random_variants + random_variant_y) * output_slice_size,
						2 * rot_index * output_slice_size))
					put_to_rotation_viewport(slice, rotation_key, true)
					yield(VisualServer, 'frame_post_draw')
					var processed_flipped_slice : Image = get_from_rotation_viewport(image_fmt, resize_factor)
					append_to_debug_image(debug_image, processed_flipped_slice, output_slice_size, 
						Vector2((x* input_max_random_variants + random_variant_y) * output_slice_size,
						(2 * rot_index + 1) * output_slice_size))
					slice_variant[rotation_key] = {
						false: processed_slice, 
						true: processed_flipped_slice
					}
				input_slices[x].append(slice_variant)
	rotated_texture_in_viewport.hide()
	emit_signal("input_image_processed")

func make_from_corners():
	if rand_seed_check.pressed:
		var random_seed_int: int = int(rand_seed_value.text)
		var random_seed = rand_seed(random_seed_int)
		rng.seed = random_seed[1]
	if input_slices.size() == 0:
		set_output_texture(null)
		return
	var tile_size: int = get_output_tile_size()
	# warning-ignore:integer_division
	var slice_size: int = int(tile_size) / 2
	var image_fmt: int = input_slices[0][0][0][false].get_format()
	var slice_rect := Rect2(0, 0, slice_size, slice_size)
	var out_image := Image.new()
	out_image.create(tile_size * int(template_size.x), tile_size * int(template_size.y), false, image_fmt)
	var preset: Array = generation_data.get_preset()
	for mask in tile_masks:
		var tile_position: Vector2 = mask['position'] * tile_size
		if mask["godot_mask"] != 0: # don't draw only center
			for place_mask in preset:
				var allowed_rotations: Array = get_allowed_mask_rotations(
						place_mask["in_mask"]["positive"], 
						place_mask["in_mask"]["negative"], 
						mask['mask'],
						place_mask["rotation_offset"])
				for rotation in allowed_rotations:
					var out_tile = place_mask["out_tile"]
					var is_flipped: bool = out_tile["flip"]
					var slice_index: int = out_tile["index"]
					var random_index: int = rng.randi_range(0, input_slices[slice_index].size()-1)
					var slice_image: Image = input_slices[slice_index][random_index][rotation][is_flipped]
					var init_rotation: int = rotate_cw(rotation, place_mask["rotation_offset"])
					var intile_offset : Vector2 = Const.ROTATION_SHIFTS[init_rotation]["vector"] * slice_size
					if is_flipped: 
						intile_offset = Const.ROTATION_SHIFTS[rotate_cw(init_rotation)]["vector"] * slice_size
					out_image.blit_rect(slice_image, slice_rect, tile_position + intile_offset)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image, 0)
	set_output_texture(itex)
	unblock_ui()

#slice: Image, rotation_key: int, color_process: int,
#		is_flipped := false
func start_overlay_processing(data: Dictionary, input_tiles: Array, overlay_rate: float, overlap_rate: float, 
		overlap_vectors: Array, overlap_vectors_is_rotatable: Array):
	var random_center_index: int = 0
	var center_image: Image = input_tiles[0][random_center_index]
	var gen_pieces: Array = data["generate_piece_indexes"]
	var gen_rotations: Array = data["generate_piece_rotations"]
#	var gen_flip_x: Array = 
#	var gen_flip_y: Array = data["generate_piece_flip_y"]
	assert (gen_pieces.size() == 8 && gen_rotations.size() == 8)
	var itex = ImageTexture.new()
	itex.create_from_image(center_image, 0)
	overlay_texture_in_viewport.texture = itex
	var rot_index: int = 0
	for mask_name in Const.MY_MASK:
		var piece_index: int = gen_pieces[rot_index]
		var random_tile_index: int = rng.randi_range(0, input_tiles[piece_index].size()-1)
		var piece_rot_index: int = data["generate_piece_rotations"][rot_index]
		var rotation_shift: int = Const.ROTATION_SHIFTS.keys()[piece_rot_index]
		var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_shift]["angle"]
		var overlay_image := Image.new()
		overlay_image.copy_from(input_tiles[piece_index][random_tile_index])
		if bool(data["generate_piece_flip_x"][rot_index]):
			overlay_image.flip_x()
		if bool(data["generate_piece_flip_y"][rot_index]):
			overlay_image.flip_y()
		var itex2 = ImageTexture.new()
		itex2.create_from_image(overlay_image, 0)
		var mask_key: int = Const.MY_MASK[mask_name]
		overlay_texture_in_viewport.material.set_shader_param("overlay_texture_%s" % mask_key, itex2)
		overlay_texture_in_viewport.material.set_shader_param("rotation_%s" % mask_key, -rotation_angle)

		var overlap_vec: Vector2 = overlap_vectors[piece_index]
		if overlap_vectors_is_rotatable[piece_index] and (rotation_angle == PI / 2 or rotation_angle == 3 * PI / 2):
			overlap_vec.x = 0.0 if overlap_vec.x == 1.0 else 1.0
			overlap_vec.y = 0.0 if overlap_vec.y == 1.0 else 1.0
		overlay_texture_in_viewport.material.set_shader_param("ovelap_direction_%s" % mask_key, overlap_vec)
		rot_index += 1

	overlay_texture_in_viewport.material.set_shader_param("overlay_rate", overlay_rate)
	overlay_texture_in_viewport.material.set_shader_param("overlap", overlap_rate)
	var is_flow_map: bool = get_color_process() == Const.COLOR_PROCESS_TYPES.FLOW_MAP
	overlay_texture_in_viewport.material.set_shader_param("is_flow_map", is_flow_map)
#	var is_flow_map: bool = color_process == Const.COLOR_PROCESS_TYPES.FLOW_MAP
#	input_texture_in_viewport.material.set_shader_param("is_flow_map", is_flow_map)


func get_from_overlay_viewport(image_fmt: int, resize_factor: float = 1.0) -> Image:
	var image := Image.new()
	var size: Vector2 = overlay_texture_in_viewport.texture.get_size()
	image.create(int(size.x), int(size.y), false, image_fmt)
	image.blit_rect(
		overlay_viewport.get_texture().get_data(),
		Rect2(Vector2.ZERO, size), 
		Vector2.ZERO)
	if resize_factor != 1.0:
		var interpolation: int = Image.INTERPOLATE_NEAREST if not smoothing_check.pressed else Image.INTERPOLATE_TRILINEAR
		image.resize(int(size.x * resize_factor), int(size.y * resize_factor), interpolation)
	return image

func generate_overlayed_tiles():
	input_overlayed_tiles = []
	var output_tile_size: int = get_output_tile_size()
	var input_image: Image = texture_in.texture.get_data()
	var min_input_tiles: Vector2 = generation_data.get_min_input_size()
	var input_tile_size: int = int(input_image.get_size().x / min_input_tiles.x)
	
	set_input_tile_size(input_tile_size, input_image)
	# warning-ignore:integer_division
	overlay_merge_rate_slider.quantize(int(input_tile_size / 2))
	# warning-ignore:integer_division
	overlay_overlap_slider.quantize(int(input_tile_size / 2))
	
	
	var max_random_variants: int = get_input_image_random_max_variants()
	setup_randomize_controls(max_random_variants > 1)
	if rand_seed_check.pressed:
		var random_seed_int: int = int(rand_seed_value.text)
		var random_seed = rand_seed(random_seed_int)
		rng.seed = random_seed[1]

	var resize_factor: float = float(output_tile_size) / float(input_tile_size)
	var new_viewport_size := Vector2(input_tile_size, input_tile_size)
	if overlay_viewport.size != new_viewport_size:
		overlay_viewport.size = new_viewport_size
		overlay_texture_in_viewport.rect_size = new_viewport_size
#	var image_input_fmt: int = input_image.get_format()
	var image_fmt: int = overlay_viewport.get_texture().get_data().get_format()
	var debug_image := Image.new()
#	var color_process: int = get_color_process()
	var debug_texture_size: Vector2 = get_debug_image_rect_size(Const.INPUT_TYPES.OVERLAY) * 2
	debug_image.create(int(debug_texture_size.x) * max_random_variants, int(debug_texture_size.y), false, image_fmt)
	var overlay_rate: float = overlay_merge_rate_slider.value
	var overlap_rate: float = overlay_overlap_slider.value
		
	var preset: Array = generation_data.get_preset()
	
	# input tile variants
	var input_tiles: Array = []
	for x in range(min_input_tiles.x):
		var tile_alternatives: Array = []
		for y in range(max_random_variants):
			var tile := Image.new()
			tile.create(input_tile_size, input_tile_size, false, image_fmt)
			var copy_rect := Rect2(x * input_tile_size, y * input_tile_size, input_tile_size, input_tile_size)
			tile.blit_rect(input_image, copy_rect, Vector2.ZERO)
			tile_alternatives.append(tile)
		input_tiles.append(tile_alternatives)
	
	overlay_texture_in_viewport.show()
	var overlap_vectors: Array = generation_data.get_overlap_vectors()
	var overlap_vector_rotations: Array = generation_data.get_overlap_vector_rotations()
	var index: int = 0 
	for data in preset:
		var int_variants: Array = []
		for variant in data["mask_variants"]:
			int_variants.append(int(variant))
		# TODO: fix - на самом деле это не зависит от max_random_variants
		# переделать - генерировать каждый тайл отдельно, а не предгененировать
		var result_tile_variants: Array = []
		for random_variant_index in range(max_random_variants):
			start_overlay_processing(data, input_tiles, overlay_rate, overlap_rate, overlap_vectors, overlap_vector_rotations)
			yield(VisualServer, 'frame_post_draw')
			var overlayed_tile: Image = get_from_overlay_viewport(image_fmt, resize_factor)
			result_tile_variants.append(overlayed_tile)
			# warning-ignore:integer_division		
			append_to_debug_image(debug_image, overlayed_tile, output_tile_size, 
				Vector2((index % 4 + 4 * random_variant_index) * output_tile_size, (index / 4) * output_tile_size))
		input_overlayed_tiles.append({
			"tile_image_variants": result_tile_variants,
			"mask_variants": int_variants,
			"variant_rotations": data["variant_rotations"]
		})
		index += 1
	overlay_texture_in_viewport.hide()
	emit_signal("input_image_processed")

func make_from_overlayed():
	set_output_texture(null)
	if input_overlayed_tiles.size() == 0:
		return
	var tile_size: int = get_output_tile_size()
	var new_viewport_size := Vector2(tile_size, tile_size)
	rotated_texture_in_viewport.show()
	if rotate_viewport.size != new_viewport_size:
		rotate_viewport.size = new_viewport_size
		rotated_texture_in_viewport.rect_size = new_viewport_size
	
#	var color_process: int = get_color_process()
	var out_image := Image.new()
	var first_tile_image: Image = input_overlayed_tiles[0]["tile_image_variants"][0]
	var image_fmt: int = first_tile_image.get_format()
	var out_image_fmt: int = rotate_viewport.get_texture().get_data().get_format()
	out_image.create(tile_size * int(template_size.x), tile_size * int(template_size.y), false, image_fmt)
#	var preset: Array = generation_data.get_preset()
	var tile_rect := Rect2(0, 0, tile_size, tile_size)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image, 0)
	var masks_use_count: Dictionary = {}
	for mask in tile_masks:
		if mask["godot_mask"] == 0:
			continue
		var mask_value = mask["mask"]
		if masks_use_count.has(mask_value):
			masks_use_count[mask_value] += 1
			if masks_use_count[mask_value] > input_overlayed_tiles[0]["tile_image_variants"].size() - 1:
				masks_use_count[mask_value] = 0
		else:
			masks_use_count[mask_value] = 0
		var tile_variant_index: int = masks_use_count[mask_value]
		var tile_position: Vector2 = mask["position"] * tile_size
		for tile_data in input_overlayed_tiles:
			var variant_index: int = tile_data["mask_variants"].find(mask_value)
			if variant_index != -1:
				var rotation_key: int = Const.ROTATION_SHIFTS.keys()[tile_data["variant_rotations"][variant_index]]
				if rotation_key != 0:
					put_to_rotation_viewport(tile_data["tile_image_variants"][tile_variant_index], rotation_key, false)
					yield(VisualServer, 'frame_post_draw')
					var tile_image: Image = get_from_rotation_viewport(out_image_fmt)
					out_image.blit_rect(tile_image, tile_rect, tile_position)
				else:
					out_image.blit_rect(tile_data["tile_image_variants"][tile_variant_index], tile_rect, tile_position)
				itex.set_data(out_image)
				set_output_texture(itex)
	rotated_texture_in_viewport.hide()
	unblock_ui()

func preprocess_input_image():
	block_ui()
	rotated_texture_in_viewport.show()
	if not check_input_texture():
		report_error("Error: Wrong input texture")
		return
	debug_input_texture.texture = null
	var generation_type: int = generation_type_select.selected
	match generation_type:
		Const.INPUT_TYPES.CORNERS:
			generate_corner_slices()
		Const.INPUT_TYPES.OVERLAY:
			generate_overlayed_tiles()

func set_output_texture(texture: Texture):
	out_texture.texture = texture
	if texture != null:
		var image_size: Vector2 = out_texture.texture.get_data().get_size()
#		print(image_size)
		out_texture.rect_size = image_size
		output_control.rect_min_size = image_size
	else:
		output_control.rect_min_size = Vector2.ZERO

func make_output_texture():
	var generation_type: int = generation_type_select.selected
	set_output_texture(null)
	match generation_type:
		Const.INPUT_TYPES.CORNERS:
			make_from_corners()
		Const.INPUT_TYPES.OVERLAY:
			make_from_overlayed()
	
	
func rotate_ccw(in_rot: int, quarters: int = 1) -> int:
	var out: int = int(clamp(in_rot, 0, 6)) - 2 * quarters
	out = out % 8
	if out < 0:
		out = 8 + out
	return out
	
func rotate_cw(in_rot: int, quarters: int = 1) -> int:
	var out: int = int(clamp(in_rot, 0, 6)) + 2 * quarters
	out = out % 8
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
# quarters_offset - это количество поворотов на 90 от квадрата (0,0) для положения на картинке (если как на картинке ставим налево вверх, то 0)
func get_allowed_mask_rotations(pos_check_mask: int, neg_check_mask: int, current_mask: int, quarters_offset: int = 0) -> Array:
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

func exit():
	godot_resource_exporter.free()
	tile_masks.empty()
	get_tree().quit()

func _on_CloseButton_pressed():
	exit()
	
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
		var directory = Directory.new();
		if not directory.file_exists(path):
			report_error("Error: Image does not exist: %s, reverting to default" % path)
			return null
		var err = image.load(path)
		if(err != 0):
			report_error("Error loading the image: %s" % path)
			return null
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, 0)
		return image_texture

func _on_TextureDialog_file_selected(path):
	load_input_texture(path)
	preprocess_input_image()
	save_settings()

func _on_TemplateDialog_file_selected(path):
#	custom_template_path = path
#	template_texture.texture = load_image_texture(path)
	load_template_texture(path)
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
	var texture_path: String = save_file_dialog.current_path
	if godot_resource_exporter.check_paths(path, texture_path):
		godot_resource_exporter.save_resource(
			path, 
			get_output_tile_size(),
			tile_masks,
			out_texture.texture.get_data().get_size(),
			save_file_dialog.current_path,
			last_tile_name
		)
	save_settings()

func setup_input_type(index: int):
	match index:
		Const.INPUT_TYPES.CORNERS:
			overlay_merge_container.hide()
			corners_merge_container.show()
			color_process_select.selected = Const.COLOR_PROCESS_TYPES.NO
			set_corner_generation_data(corners_merge_type_select.selected)
			for node in get_tree().get_nodes_in_group("overlay_settings"):
				node.hide()
			for node in get_tree().get_nodes_in_group("corners_settings"):
				node.show()
		Const.INPUT_TYPES.OVERLAY:
			corners_merge_container.hide()
			overlay_merge_container.show()
			set_overlay_generation_data(overlay_merge_type_select.selected)
			for node in get_tree().get_nodes_in_group("corners_settings"):
				node.hide()
			for node in get_tree().get_nodes_in_group("overlay_settings"):
				node.show()


	
func _on_InputType_item_selected(index):
	setup_input_type(index)
	preprocess_input_image()
	save_settings()

func _on_ColorProcessType_item_selected(index):
	preprocess_input_image()
	save_settings()

func _on_ReloadButton_pressed():
	load_input_texture(last_input_texture_path)
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

func set_corner_generation_data(index: int):
	last_generator_preset_path = Const.CORNERS_INPUT_PRESETS_DATA_PATH[index]
	generation_data = GenerationData.new(last_generator_preset_path)
	example_texture.texture = load(generation_data.get_example_path())

func _on_CornersOptionButton_item_selected(index):
	set_corner_generation_data(index)
	preprocess_input_image()
	save_settings()

func set_overlay_generation_data(index: int):
	last_generator_preset_path = Const.OVERLAY_INPUT_PRESETS_DATA_PATH[index]
	generation_data = GenerationData.new(last_generator_preset_path)
	example_texture.texture = load(generation_data.get_example_path())

func _on_OverlayOptionButton_item_selected(index):
	set_overlay_generation_data(index)
	preprocess_input_image()
	save_settings()

func get_debug_image_rect_size(input_type: int) -> Vector2:
	var output_tile_size: int = get_output_tile_size()
	var size := Vector2.ZERO
	match input_type:
		Const.INPUT_TYPES.CORNERS:
			# warning-ignore:integer_division
			var slice_size: int = output_tile_size / 2
			var min_size: Vector2 = generation_data.get_min_input_size()
			size.x = slice_size * min_size.x
			size.y = slice_size * min_size.y * 8
		Const.INPUT_TYPES.OVERLAY:
#			var min_size: Vector2 = generation_data.get_min_input_size()
			size.x = 4 * output_tile_size # input_tile_size_vector.x
			size.y = 4 * output_tile_size * 3
	return size

func update_output_bg_texture_scale():
	var tile_size: int = get_output_tile_size()
	var output_scale_factor: float = float(tile_size) / float(Const.DEFAULT_OUTPUT_SIZE)
	var output_scale := Vector2(output_scale_factor, output_scale_factor)
	out_bg_texture.rect_scale = output_scale
	out_bg_texture.rect_size = output_control.rect_size / output_scale_factor
	output_control.get_node("TileSizeLabel").text = Const.OUTPUT_SIZES[tile_size]
	debug_input_control.rect_min_size = get_debug_image_rect_size(generation_type_select.selected)
	debug_input_texture_bg.rect_scale = output_scale
	debug_input_texture_bg.rect_size = debug_input_control.rect_size / output_scale_factor
	debug_input_control.get_node("TileSizeLabel").text = Const.OUTPUT_SIZES[tile_size]

func _on_SizeOptionButton_item_selected(index):
	update_output_bg_texture_scale()
	preprocess_input_image()
	save_settings()

func block_ui():
	is_ui_blocked = true
	for node in get_tree().get_nodes_in_group("blockable"):
		if node is Button:
			node.disabled = true
	
func unblock_ui():
	is_ui_blocked = false
	for node in get_tree().get_nodes_in_group("blockable"):
		if node is Button and not node.is_in_group("really_disabled"):
			node.disabled = false
		if is_slider_changed:
			preprocess_input_image()
	is_slider_changed = false

func _on_RateSlider_released(value):
	if not is_ui_blocked:
		preprocess_input_image()
		save_settings()
#	else:
#		is_slider_changed = true
		
func rebuild_output():
	var generation_type: int = generation_type_select.selected
	match generation_type:
		Const.INPUT_TYPES.CORNERS:
			make_from_corners()
		Const.INPUT_TYPES.OVERLAY:
			preprocess_input_image()

func _on_RemakeButton_pressed():
	rebuild_output()
	reset_saved()

func _on_LineEdit_text_entered(new_text):
	rebuild_output()
	save_settings()

func _on_ExampleButton_pressed():
	load_input_texture(generation_data.get_example_path())
	preprocess_input_image()
	save_settings()

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		exit()

func _on_OverlapSlider_released(value):
	if not is_ui_blocked:
		preprocess_input_image()
		save_settings()

func _on_Smoothing_button_up():
	preprocess_input_image()
	save_settings()

func _on_RandomCheckButton_button_up():
#		print(rand_seed_check.get_groups())
	var button_pressed: bool = rand_seed_check.pressed
	rand_seed_value.editable = button_pressed
	if not button_pressed:
		rng.randomize()
		rand_seed_value.text = ""
		rebuild_output()
		save_settings()

func reset_saved():
	saved_tile_names = []
	saved_texture_rects = []

func _on_Freeze_pressed():
	saved_tile_names.append(last_tile_name)
	saved_texture_rects.append(last_tile_name)

func report_error(error_text: String):
	print(error_text)
	popup_dialog.dialog_text += error_text + "\n"
	popup_dialog.popup_centered()

func _on_PopupDialog_confirmed():
	popup_dialog.dialog_text = ""
