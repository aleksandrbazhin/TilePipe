extends Node

signal input_image_processed()

const SIZES: Dictionary = {
	8: "8x8",
	16: "16x16",
	32: "32x32",
	64: "64x64",
	128: "128x128"
}
const TEMPLATE_TILE_SIZE: int = 64
const DEFAULT_SIZE: int = 64

const SETTINGS_PATH: String = "user://tilepipe_settings.save"

const GODOT_MASK: Dictionary = {
	"TOP_LEFT": 1,
	"TOP": 2,
	"TOP_RIGHT": 4,
	"LEFT": 8,
	"CENTER": 16,
	"RIGHT": 32,
	"BOTTOM_LEFT": 64,
	"BOTTOM": 128,
	"BOTTOM_RIGHT": 256
}
const GODOT_MASK_CHECK_POINTS := {
	GODOT_MASK["TOP_LEFT"]: Vector2(10, 10),
	GODOT_MASK["TOP"]: Vector2(32, 10),
	GODOT_MASK["TOP_RIGHT"]: Vector2(54, 10),
	GODOT_MASK["LEFT"]: Vector2(10, 32),
	GODOT_MASK["CENTER"]: Vector2(32, 32),
	GODOT_MASK["RIGHT"]: Vector2(54, 32),
	GODOT_MASK["BOTTOM_LEFT"]: Vector2(10, 54),
	GODOT_MASK["BOTTOM"]: Vector2(32, 54),
	GODOT_MASK["BOTTOM_RIGHT"]: Vector2(54, 54)
}

# so it can be rotated by multiplication
const MY_MASK: Dictionary = {
	"TOP": 1,
	"TOP_RIGHT": 2,
	"RIGHT": 4,
	"BOTTOM_RIGHT": 8,
	"BOTTOM": 16,
	"BOTTOM_LEFT": 32,
	"LEFT": 64,
	"TOP_LEFT": 128,
}
const TEMPLATE_MASK_CHECK_POINTS := {
	MY_MASK["TOP"]: Vector2(32, 10),
	MY_MASK["TOP_RIGHT"]: Vector2(54, 10),
	MY_MASK["RIGHT"]: Vector2(54, 32),
	MY_MASK["BOTTOM_RIGHT"]: Vector2(54, 54),
	MY_MASK["BOTTOM"]: Vector2(32, 54),
	MY_MASK["BOTTOM_LEFT"]: Vector2(10, 54),
	MY_MASK["LEFT"]: Vector2(10, 32),
	MY_MASK["TOP_LEFT"]: Vector2(10, 10)
}

## masks are in 4-base count system like
##  1
## 64#4      
##  16
## where 
## 0 - no land
## 1 - full land
## 2 - border going out of tile
## 3 - border staying in tile
#var IMAGE_SLICE_MASK_VALUES := [
#	[1, 1, 1, 1],
#	[2, 2, 1, 1],
#	[0, 3, 1, 2],
#	[0, 0, 3, 3],
#	[2, 3, 1, 1],
#]

# key is bit lenght shift to rotate TEMPLATE_MASK_CHECK_POINTS to that angle
const ROTATION_SHIFTS := {
	0: {"vector": Vector2(1, 0), "angle": 0.0},
	2: {"vector": Vector2(1, 1), "angle": PI / 2},
	4: {"vector": Vector2(0, 1), "angle": PI},
	6: {"vector": Vector2(0, 0), "angle": 3 * PI / 2},
}
const FLIP_HORIZONTAL_KEYS := [0, 4]

# positive mask defines mask values where neighbour must exist (from 1 - north, clockwise)
# negative mask defines mask values where neighbour must not exist (from 1 - north, clockwise)
# index is the index of input slice
const CHECK_MASKS_IN_OUT := [
	#  corner
	{
		"in_mask": {
			"positive": 0,
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"] | MY_MASK["RIGHT"] | MY_MASK["BOTTOM_RIGHT"],
		},
		"out_tile": {"index": 4, "flip": false}
	},
#	{
#		"in_mask": {
#			"positive": 0,
#			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"] | MY_MASK["RIGHT"] | MY_MASK["BOTTOM_RIGHT"],
#		},
#		"out_tile": {"index": 4, "flip": true}
#	},
	# border with corner
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"],
			"negative": MY_MASK["TOP"] | MY_MASK["RIGHT"]
		},
		"out_tile": {"index": 3, "flip": true}
	},	
	{
		"in_mask": {
			"positive": MY_MASK["RIGHT"],
			"negative": MY_MASK["LEFT"] | MY_MASK["TOP"]
		},
		"out_tile": {"index": 3, "flip": false}
	},

	# border
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"] | MY_MASK["RIGHT"],
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"]
		},
		"out_tile": {"index": 2, "flip": false}
	},
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"] | MY_MASK["RIGHT"],
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"]
		},
		"out_tile": {"index": 2, "flip": true}
	},
	# full without corner
	{
		"in_mask": {
			"positive": 5,
			"negative": 2
		},
		"out_tile":  {"index": 1, "flip": false}
	},
	# full
	{
		"in_mask": {
			"positive": 7,
			"negative": 0
		},
		"out_tile":  {"index": 0, "flip": false}
	},
]

var MIN_IMAGE_SIZE := Vector2(5, 1)
var template_size: Vector2
# input slice = {
#	0: {0: {false: Image, true: Image}, 2: , 4: , 6:}
#	1: ... }
var input_slices: Dictionary = {}
# tile_masks = [{"mask": int, "godot_mask": int, "position" Vector2}, ...]
var tile_masks: Array = []

onready var texture_file_dialog: FileDialog = $TextureDialog
onready var template_file_dialog: FileDialog = $TemplateDialog
onready var save_file_dialog: FileDialog = $SaveTextureDialog
onready var save_resource_dialog: FileDialog = $SaveTextureResourceDialog
onready var texture_in: TextureRect = $Center/Panel/HBox/Images/InContainer/VBoxInput/TextureRect
onready var out_texture: TextureRect = $Center/Panel/HBox/Images/OutTextureRect
onready var template_texture: TextureRect = $Center/Panel/HBox/Images/TemplateTextureRect
onready var size_select: OptionButton = $Center/Panel/HBox/Settings/OptionButton
onready var slice_viewport: Viewport = $Center/Panel/HBox/Images/InContainer/VBoxViewport/ViewportContainer/Viewport
onready var texture_in_viewport: TextureRect = $Center/Panel/HBox/Images/InContainer/VBoxViewport/ViewportContainer/Viewport/TextureRect
onready var debug_input_texture: TextureRect = $Center/Panel/HBox/Images/InContainer/TextureRect2
onready var slice_slider: HSlider = $Center/Panel/HBox/Images/InContainer/VBoxViewport/HBoxContainer/HSlider
onready var export_type_select: CheckButton = $Center/Panel/HBox/Settings/Resourse/AutotileSelect
onready var description_select_box: HBoxContainer = $Center/Panel/HBox/Settings/DescriptionResourse
onready var export_manual_resource_type_select: CheckButton = $Center/Panel/HBox/Settings/DescriptionResourse/Select
onready var normal_map_checkbutton: CheckButton = $Center/Panel/HBox/Images/InContainer/VBoxInput/Control/HBoxContainer/CheckButton

func _ready():
	print(get_allowed_mask_rotations(0, 5, 21))
	connect("input_image_processed", self, "make_output_texture")
	size_select.clear()
	for size in SIZES:
		size_select.add_item(SIZES[size])
	load_settings()
	generate_tile_masks()
	preprocess_input_image()

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_CloseButton_pressed()

const DEFAULT_SETTINGS: Dictionary = {
	"last_texture_path": "res://addons/TilePipe/in_green.png",
	"last_template_path": "res://addons/TilePipe/template.png",
	"last_save_texture_path": "res://generated.png",
	"last_save_texture_resource_path": "res://generated.png",
	"output_tile_size": DEFAULT_SIZE
}

func get_setting_values(load_defaluts: bool = false) -> Dictionary:
	if load_defaluts:
		return DEFAULT_SETTINGS
	else:
		return {
		"last_texture_path": texture_file_dialog.current_path,
		"last_template_path": template_file_dialog.current_path,
		"last_save_texture_path": save_file_dialog.current_path,
		"last_save_texture_resource_path": save_resource_dialog.current_path,
		"output_tile_size": SIZES.keys()[size_select.selected],
	}

func save_settings(store_defaults: bool = false):
	var save = File.new()
	save.open(SETTINGS_PATH, File.WRITE)
	var data := get_setting_values(store_defaults) 
	save.store_line(to_json(data))
	save.close()

func apply_settings(data: Dictionary):
	texture_file_dialog.current_path = data["last_texture_path"]
	texture_in.texture = load(data["last_texture_path"])
	template_file_dialog.current_path = data["last_template_path"]
	template_texture.texture = load(data["last_template_path"])
	save_file_dialog.current_path = data["last_save_texture_path"]
	save_resource_dialog.current_path = data["last_save_texture_resource_path"]
	size_select.selected = SIZES.keys().find(int(data["output_tile_size"]))

func setting_exist() -> bool:
	var save = File.new()
	return save.file_exists(SETTINGS_PATH)

func load_settings():
#	save_settings(true) # uncomment on change of save file structure
	if not setting_exist():
		save_settings(true)
	var save = File.new()
	save.open(SETTINGS_PATH, File.READ)
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
	if template_image_size.x < TEMPLATE_TILE_SIZE and template_image_size.y < TEMPLATE_TILE_SIZE:
		return false
	return true

func compute_template_size() -> Vector2:
	var template_image: Image = template_texture.texture.get_data()
	return template_image.get_size() / TEMPLATE_TILE_SIZE

func get_template_mask_value(template_image: Image, x: int, y: int, 
		mask_check_points: Dictionary = TEMPLATE_MASK_CHECK_POINTS) -> int:
	var mask_value: int = 0
	template_image.lock()
	for mask in mask_check_points:
		var pixel_x: int = x * TEMPLATE_TILE_SIZE + mask_check_points[mask].x
		var pixel_y: int = y * TEMPLATE_TILE_SIZE + mask_check_points[mask].y
		if not template_image.get_pixel(pixel_x, pixel_y).is_equal_approx(Color.white):
			mask_value += mask
	template_image.unlock()
	return mask_value

func generate_tile_masks():
	for label in template_texture.get_children():
		label.queue_free()
	if not check_template_texture():
		print("WRONG template texture")
		return
	template_size = compute_template_size()
	var template_image: Image = template_texture.texture.get_data()
	for x in range(template_size.x):
		for y in range(template_size.y):
			var mask_value: int = get_template_mask_value(template_image, x, y) 
			var godot_mask_value: int = get_template_mask_value(template_image, x, y, GODOT_MASK_CHECK_POINTS)
			tile_masks.append({"mask": mask_value, "position": Vector2(x, y), "godot_mask": godot_mask_value })
			var mask_text_label := Label.new()
			mask_text_label.add_color_override("font_color", Color(0, 0.05, 0.1))
			mask_text_label.text = str(godot_mask_value)
			mask_text_label.rect_position = Vector2(x, y) * DEFAULT_SIZE + Vector2(5, 5)
			template_texture.add_child(mask_text_label)

func put_to_viewport(slice: Image, rotation_key: int, is_flipped := false, is_normal_map := false ):
	var flip_x := false
	var flip_y := false
	if is_flipped:
		if rotation_key in FLIP_HORIZONTAL_KEYS:
			flip_x = true
		else:
			flip_y = true
	var rotation_angle: float = ROTATION_SHIFTS[rotation_key]['angle']
	var itex = ImageTexture.new()
	itex.create_from_image(slice)
	texture_in_viewport.texture = itex
	texture_in_viewport.material.set_shader_param("rotation", -rotation_angle)
	texture_in_viewport.material.set_shader_param("is_flipped_x", flip_x)
	texture_in_viewport.material.set_shader_param("is_flipped_y", flip_y)
	texture_in_viewport.material.set_shader_param("is_normal_map", is_normal_map)

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

# invert for 3 slice
func get_input_flip(index: int, flip: bool) -> bool:
	return flip if index != 3 else not flip

func preprocess_input_image():
	texture_in_viewport.show()
	input_slices = {}
	var output_tile_size: int = SIZES.keys()[size_select.selected]
	if not check_input_texture():
		print("WRONG input texture")
		return
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
	var is_normal_map = normal_map_checkbutton.pressed
	debug_image.create(int(output_slice_size * MIN_IMAGE_SIZE.x),
		int(output_slice_size * MIN_IMAGE_SIZE.y * 8), false, image_fmt)
	for x in range(MIN_IMAGE_SIZE.x):
		input_slices[x] = {}
		var slice := Image.new()
		slice.create(input_slice_size, input_slice_size, false, image_input_fmt)
		slice.blit_rect(input_image, Rect2(x * input_slice_size, 0, input_slice_size, input_slice_size), Vector2.ZERO)
		for rot_index in ROTATION_SHIFTS.size():
			var rotation_key: int = ROTATION_SHIFTS.keys()[rot_index]

			put_to_viewport(slice, rotation_key, get_input_flip(x, false), is_normal_map)
			yield(VisualServer, 'frame_post_draw')
			var processed_slice : Image = get_from_viewport(image_fmt, resize_factor)
			debug_image.blit_rect(
				processed_slice,
				Rect2(0, 0, output_slice_size, output_slice_size), 
				Vector2(x * output_slice_size, 2*rot_index * output_slice_size)
			)
			var itex = ImageTexture.new()
			itex.create_from_image(debug_image)
			debug_input_texture.texture = itex

			put_to_viewport(slice, rotation_key, get_input_flip(x, true), is_normal_map)
			yield(VisualServer, 'frame_post_draw')
			var processed_flipped_slice : Image = get_from_viewport(image_fmt, resize_factor)
			debug_image.blit_rect(
				processed_flipped_slice,
				Rect2(0, 0, output_slice_size, output_slice_size), 
				Vector2(x * output_slice_size, (2*rot_index + 1) * output_slice_size)
			)
			itex.create_from_image(debug_image)
			debug_input_texture.texture = itex
			
			input_slices[x][rotation_key] = {
				false: processed_slice, 
				true: processed_flipped_slice
			}

	texture_in_viewport.hide()
#	display_slice()
	emit_signal("input_image_processed")

func display_slice(index: int = -1):
	if index == -1:
		index = int(slice_slider.value - 1)
#	put_to_viewport(input_slices[index][0][true], PI)

func make_output_texture():
	if input_slices.size() == 0:
		return
	var tile_size: int = SIZES.keys()[size_select.selected]
	# warning-ignore:integer_division
	var slice_size: int = int(tile_size) / 2
	var image_fmt: int = input_slices[0][0][true].get_format()
	var slice_rect := Rect2(0, 0, slice_size, slice_size)
	var out_image := Image.new()
	out_image.create(tile_size * int(template_size.x), tile_size * int(template_size.y), false, image_fmt)
	for mask in tile_masks:
		var tile_position: Vector2 = mask['position'] * tile_size
		if mask["godot_mask"] != 0: # don't draw only center
			for in_out_mask in CHECK_MASKS_IN_OUT:
				var allowed_rotations: Array = get_allowed_mask_rotations(
						in_out_mask["in_mask"]["positive"], 
						in_out_mask["in_mask"]["negative"], mask['mask'])
				for rotation in allowed_rotations:
					var out_tile = in_out_mask["out_tile"]
					var is_flipped: bool = out_tile["flip"]
					var slice_index: int = out_tile["index"]
					var slice_image: Image = input_slices[slice_index][rotation][is_flipped]
					var intile_offset : Vector2 = ROTATION_SHIFTS[rotation]["vector"] * slice_size
					if is_flipped: 
						intile_offset = ROTATION_SHIFTS[rotate_clockwise(rotation)]["vector"] * slice_size
					out_image.blit_rect(slice_image, slice_rect, tile_position + intile_offset)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image)
	out_texture.texture = itex

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
	for rotation in ROTATION_SHIFTS:
		var rotated_check: int = rotate_check_mask(pos_check_mask, rotation)
		var satisfies_check := false
		if current_mask & rotated_check == rotated_check:
			satisfies_check = true
		if satisfies_check and neg_check_mask != 0: # check negative mask
			rotated_check = rotate_check_mask(neg_check_mask, rotation)
			var inverted_cgeck: int = (~rotated_check & 0xFF)
#			print(rotated_check, "  ", inverted_cgeck, "  ", current_mask &inverted_cgeck, " ", -rotated_check)
			if current_mask & inverted_cgeck != 0:
				satisfies_check = false
		if satisfies_check:
			rotations.append(rotation)
	return rotations

func tile_name_from_position(pos: Vector2) -> String:
	return "%d_%d" % [pos.x, pos.y]

func make_manual_resource_data(path: String) -> String:
	var tile_size: int = SIZES.keys()[size_select.selected]
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=3 format=2]\n"
	out_string += "\n[ext_resource path=\"%s\" type=\"Texture\" id=1]\n" % path
	if export_manual_resource_type_select.pressed:
		out_string += "[ext_resource path=\"res://addons/TilePipe/tilesheet_description.gd\" type=\"Script\" id=2]\n"
	out_string += "\n[resource]\n"
	var count: int = 0
	var tile_lines: PoolStringArray = []
	var tile_description_lines: PoolStringArray = []
	for mask in tile_masks:
		var pos: Vector2 = mask["position"]
		tile_lines.append("%d/name = \"%s\"" % [count, tile_name_from_position(pos)])
		tile_lines.append("%d/texture = ExtResource( 1 )" % count)
		tile_lines.append("%d/tex_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/modulate = Color( 1, 1, 1, 1 )" % count)
		tile_lines.append("%d/region = Rect2( %d, %d, %d, %d )" % [count, 
						tile_size * pos.x, tile_size * pos.y, tile_size, tile_size])
		tile_lines.append("%d/tile_mode = 0" % count)
		tile_lines.append("%d/occluder_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/navigation_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/shape_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )" % count)
		tile_lines.append("%d/shape_one_way = false" % count)
		tile_lines.append("%d/shape_one_way_margin = 0.0" % count)
		tile_lines.append("%d/shapes = [  ]" % count)
		tile_lines.append("%d/z_index = 0" % count)
		count += 1
		tile_description_lines.append("%d: \"%s\"" % [mask['godot_mask'], tile_name_from_position(pos)])
	out_string += tile_lines.join("\n")
	if export_manual_resource_type_select.pressed:
		out_string += "\nscript = ExtResource( 2 )\nreplacements_table = {\n"
		out_string += tile_description_lines.join(",\n")
		out_string += "\n}"
	return out_string

func make_autotile_resource_data(path: String) -> String:
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=3 format=2]\n"
	out_string += "\n[ext_resource path=\"%s\" type=\"Texture\" id=1]\n" % path
	out_string += "\n[resource]\n"
	var tile_size: int = SIZES.keys()[size_select.selected]
	var texture_size: Vector2 = out_texture.texture.get_data().get_size()
	var mask_out_array: PoolStringArray = []
	for mask in tile_masks:
		mask_out_array.append("Vector2 ( %d, %d )" % [mask['position'].x, mask['position'].y])
		mask_out_array.append(mask['godot_mask'])
	out_string += "0/name = \"0_0\"\n"
	out_string += "0/texture = ExtResource( 1 )\n"
	out_string += "0/tex_offset = Vector2( 0, 0 )\n"
	out_string += "0/modulate = Color( 1, 1, 1, 1 )\n"
	out_string += "0/region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += "0/tile_mode = 1\n"
	out_string += "0/autotile/bitmask_mode = 1\n"
	out_string += "0/autotile/bitmask_flags = [%s]\n" % mask_out_array.join(", ")
	out_string += "0/autotile/icon_coordinate = Vector2( 0, 0 )\n"
	out_string += "0/autotile/tile_size = Vector2( %d, %d )\n" % [tile_size, tile_size]
	out_string += "0/autotile/spacing = 0\n"
	out_string += "0/autotile/occluder_map = [  ]\n"
	out_string += "0/autotile/navpoly_map = [  ]\n"
	out_string += "0/autotile/priority_map = [  ]\n"
	out_string += "0/autotile/z_index_map = [  ]\n"
	out_string += "0/occluder_offset = Vector2( 0, 0 )\n"
	out_string += "0/navigation_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )\n"
	out_string += "0/shape_one_way = false\n"
	out_string += "0/shape_one_way_margin = 0.0\n"
	out_string += "0/shapes = [  ]\n"
	out_string += "0/z_index = 0\n"
	return out_string

const IGNORE_GODOT_MASK: int = GODOT_MASK["TOP_LEFT"] | GODOT_MASK["TOP_RIGHT"] | \
			GODOT_MASK["BOTTOM_LEFT"] | GODOT_MASK["BOTTOM_LEFT"] | GODOT_MASK["CENTER"]
func compute_tile_replacement_data() -> Dictionary:
	var data: Dictionary = {}
	for mask in tile_masks:
		data[mask["godot_mask"]] = tile_name_from_position(mask["position"])
	return data

func _on_CloseButton_pressed():
	tile_masks.empty()
	get_tree().quit()

func _on_Save_pressed():
	save_file_dialog.popup_centered()

func _on_Save2_pressed():
	save_resource_dialog.popup_centered()

func _on_TextureDialog_file_selected(path):
	texture_in.texture = load(path)
	preprocess_input_image()
	save_settings()

func _on_TemplateDialog_file_selected(path):
	template_texture.texture = load(path)
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

func _on_OptionButton_item_selected(_index):
	preprocess_input_image()
	save_settings()

func _on_SaveTextureDialog2_file_selected(path: String):
	save_texture_png(path)
	var output_string : String
	if export_type_select.pressed:
		output_string = make_autotile_resource_data(path)
	else:
		output_string = make_manual_resource_data(path)
	var tileset_resource_path: String = path.get_basename( ) + ".tres"
	var file = File.new()
	file.open(tileset_resource_path, File.WRITE)
	file.store_string(output_string)
	file.close()
	save_settings()

func _on_AutotileSelect_toggled(button_pressed):
	description_select_box.visible = not button_pressed

func _on_CheckButton_toggled(button_pressed):
	preprocess_input_image()
