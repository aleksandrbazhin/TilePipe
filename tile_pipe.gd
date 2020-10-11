extends Node

const SIZES: Dictionary = {
	8: "8x8",
	16: "16x16",
	32: "32x32",
	64: "64x64",
	128: "128x128"
}
const TEMPLATE_TILE_SIZE: int = 64
const DEFAULT_SIZE: int = 64
const TEMPLATE_SIZE_3x3 := Vector2(12, 4)
const TEMPLATE_SIZE_2x2 := Vector2(4, 4)
var template_size: Vector2 = TEMPLATE_SIZE_3x3

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

var MIN_IMAGE_SIZE := Vector2(5, 1)

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
const ROTATION_SHIFTS = {
	0: {"vector": Vector2(1, 0), "angle": 0.0},
	2: {"vector": Vector2(1, 1), "angle": PI / 2},
	4: {"vector": Vector2(0, 1), "angle": PI},
	6: {"vector": Vector2(0, 0), "angle": 3 * PI / 2},
}

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
		"out_tile": {"index": 3, "flip": false}
	},
#	{"in_mask": {"positive": 0, "negative": 241}, "out_tile": {"index": 3, "flip": true}},
	# border with corner
	{
		"in_mask": {
			"positive": MY_MASK["RIGHT"],
			"negative": MY_MASK["LEFT"] | MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"]
		},
		"out_tile": {"index": 2, "flip": false}
	},
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"],
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"] | MY_MASK["RIGHT"]
		},
		"out_tile": {"index": 2, "flip": true}
	},
	# border
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"] | MY_MASK["RIGHT"],
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"]
		},
		"out_tile": {"index": 4, "flip": false}
	},
	{
		"in_mask": {
			"positive": MY_MASK["LEFT"] | MY_MASK["RIGHT"],
			"negative": MY_MASK["TOP_LEFT"] | MY_MASK["TOP"] | MY_MASK["TOP_RIGHT"]
		},
		"out_tile": {"index": 4, "flip": true}
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


signal input_image_processed()

onready var texture_file_dialog: FileDialog = $TextureDialog
onready var template_file_dialog: FileDialog = $TemplateDialog
onready var save_file_dialog: FileDialog = $SaveTextureDialog
onready var texture_in: TextureRect = $Center/Panel/HBox/Images/InContainer/VBoxInput/TextureRect
onready var out_texture: TextureRect = $Center/Panel/HBox/Images/OutTextureRect
onready var template_texture: TextureRect = $Center/Panel/HBox/Images/TemplateTextureRect
onready var toggle_2x2: CheckButton = $Center/Panel/HBox/Settings/Small2x2/Select2x2
onready var toggle_3x3_min: CheckButton = $Center/Panel/HBox/Settings/Min/min3x3
onready var toggle_3x3_full: CheckButton = $Center/Panel/HBox/Settings/Full/full3x3
onready var toggle_3x3_super: CheckButton = $Center/Panel/HBox/Settings/Super/custom3x3
onready var size_select: OptionButton = $Center/Panel/HBox/Settings/OptionButton
onready var slice_viewport: Viewport = $Center/Panel/HBox/Images/InContainer/VBoxViewport/ViewportContainer/Viewport
onready var texture_in_viewport: TextureRect = $Center/Panel/HBox/Images/InContainer/VBoxViewport/ViewportContainer/Viewport/TextureRect
onready var debug_input_texture: TextureRect = $Center/Panel/HBox/Images/InContainer/TextureRect2
onready var slice_slider: HSlider = $Center/Panel/HBox/Images/InContainer/VBoxViewport/HBoxContainer/HSlider
onready var export_type_select: CheckButton = $Center/Panel/HBox/Settings/Resourse/AutotileSelect
onready var description_select_box: HBoxContainer = $Center/Panel/HBox/Settings/DescriptionResourse
onready var export_manual_resource_type_select: CheckButton = $Center/Panel/HBox/Settings/DescriptionResourse/Select

onready var base_path: String = "res://addons/TilePipe"

# tile_masks = [{"mask": int, "godot_mask": int, "position" Vector2}, ...]
var tile_masks: Array = []

func check_input_texture(_tile_size: int = DEFAULT_SIZE) -> bool:
	if not is_instance_valid(texture_in.texture):
		return false
#	var image: Image = texture_in.texture.get_data()
#	if image.get_size().x < MIN_IMAGE_SIZE.x * tile_size / 2 or \
#			image.get_size().x < MIN_IMAGE_SIZE.y * tile_size / 2:
#		return false
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

func put_to_viewport(slice: Image, rotation : float = 0.0):
	texture_in_viewport.texture = null
	var itex = ImageTexture.new()
	itex.create_from_image(slice)
	texture_in_viewport.texture = itex
	texture_in_viewport.material.set_shader_param("rotation", -rotation)

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

# input slice = {
#	0: {0: {false: Image, true: Image}, 2: , 4: , 6:}
#	1: ... }
var input_slices: Dictionary = {}

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
#	print(slice_viewport.size, " - > ", new_viewport_size)
	if slice_viewport.size != new_viewport_size:
		slice_viewport.size = new_viewport_size
		texture_in_viewport.rect_size = new_viewport_size
	var image_fmt: int = input_image.get_format()
	var debug_image := Image.new()
	debug_image.create(int(output_slice_size * MIN_IMAGE_SIZE.x),
		int(output_slice_size * MIN_IMAGE_SIZE.y * 8), false, image_fmt)
	for x in range(MIN_IMAGE_SIZE.x):
		input_slices[x] = {}
		var slice := Image.new()
		slice.create(input_slice_size, input_slice_size, false, image_fmt)
		slice.blit_rect(input_image, Rect2(x * input_slice_size, 0, input_slice_size, input_slice_size), Vector2.ZERO)
		var slice_flipped := Image.new()
		slice_flipped.create(input_slice_size, input_slice_size, false, image_fmt)
		slice_flipped.copy_from(slice)
		for rot_index in ROTATION_SHIFTS.size():
			var rot_shift_bits: int = ROTATION_SHIFTS.keys()[rot_index]
			var rot_angle: float = ROTATION_SHIFTS[rot_shift_bits]['angle']
			put_to_viewport(slice, rot_angle)
			yield(VisualServer, 'frame_post_draw')
			var processed_slice : Image = get_from_viewport(image_fmt, resize_factor)
			var processed_flipped_slice : Image = get_from_viewport(image_fmt, resize_factor)
			if rot_index in [0, 2]:
				processed_flipped_slice.flip_x()
			else:
				processed_flipped_slice.flip_y()
			input_slices[x][rot_shift_bits] = {
				false: processed_slice, 
				true: processed_flipped_slice
			}
			debug_image.blit_rect(
				processed_slice,
				Rect2(0, 0, output_slice_size, output_slice_size), 
				Vector2(x * output_slice_size, rot_index * output_slice_size)
			)
			debug_image.blit_rect(
				processed_flipped_slice,
				Rect2(0, 0, output_slice_size, output_slice_size), 
				Vector2(x * output_slice_size, (rot_index + 4) * output_slice_size)
			)
			var itex = ImageTexture.new()
			itex.create_from_image(debug_image)
			debug_input_texture.texture = itex
	texture_in_viewport.hide()
#	display_slice()
	emit_signal("input_image_processed")

func display_slice(index: int = -1):
	if index == -1:
		index = int(slice_slider.value - 1)
	put_to_viewport(input_slices[index][0][true], PI)

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
				for rotation in check_mask_template(in_out_mask["in_mask"]["positive"], in_out_mask["in_mask"]["negative"], mask['mask']):
					var out_tile = in_out_mask["out_tile"]
					var is_flipped: bool = out_tile["flip"]
					var slice_index: int = out_tile["index"]
					var slice_image: Image = input_slices[slice_index][rotation][is_flipped]
					var intile_offset := Vector2.ZERO
					if not is_flipped: 
						intile_offset += ROTATION_SHIFTS[rotation]["vector"] * slice_size
					else:
						intile_offset += ROTATION_SHIFTS[rotate_clockwise(rotation)]["vector"] * slice_size
	#				if in_out_mask["in_mask"]["positive"] == 0 and mask['mask'] == 0:
	#					print(mask['mask'])
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

func check_mask_template(pos_check_mask: int, neg_check_mask: int, current_mask: int) -> Array:
#	print("Now checking: ", current_mask, " for mask ", check_mask)
	var rotations: Array = []
	for rotation in ROTATION_SHIFTS:
		var rotated_check: int = rotate_check_mask(pos_check_mask, rotation)
		var satisfies_check := false
		if current_mask & rotated_check == rotated_check:
			satisfies_check = true
		if satisfies_check and neg_check_mask != 0: # check negative mask
			rotated_check = rotate_check_mask(neg_check_mask, rotation)
			if current_mask |~ rotated_check == -rotated_check:
	#			print ("mask found at ", ROTATION_SHIFTS[rot]["angle"]/PI*180)
				satisfies_check = false
		if satisfies_check:
			rotations.append(rotation)
	return rotations

func _ready():
	connect("input_image_processed", self, "make_output_texture")
	for size in SIZES:
		size_select.add_item(SIZES[size])
	size_select.selected = SIZES.keys().find(DEFAULT_SIZE)
	generate_tile_masks()
	preprocess_input_image()

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_CloseButton_pressed()

func _on_CloseButton_pressed():
	tile_masks.empty()
	get_tree().quit()

func _on_ComputeButton_pressed():
	make_output_texture()

func _on_Save_pressed():
	save_file_dialog.popup_centered()

func _on_3x3min_toggled(button_pressed):
	toggle_2x2.pressed = not button_pressed
	if button_pressed:
		template_size = TEMPLATE_SIZE_3x3
	else:
		template_size = TEMPLATE_SIZE_2x2
#	toggle_3x3_full.pressed = not button_pressed
#	toggle_3x3_super.pressed = not button_pressed

func _on_3x3full_toggled(button_pressed):
	toggle_3x3_min.pressed = not button_pressed
#	toggle_2x2.pressed = not button_pressed
#	toggle_3x3_min.pressed = not button_pressed
#	toggle_3x3_super.pressed = not button_pressed

func _on_Help_pressed():
	pass # Replace with function body.

func _on_Save2_pressed():
	$SaveTextureDialog2.popup_centered()

func _on_TextureDialog_file_selected(path):
	texture_in.texture = load(path)
	preprocess_input_image()

func _on_TemplateDialog_file_selected(path):
	template_texture.texture = load(path)
	generate_tile_masks()
	make_output_texture()
#	preprocess_input_image()

func _on_TemplateButton_pressed():
	template_file_dialog.popup_centered()

func _on_Button_pressed():
	texture_file_dialog.popup_centered()

func _on_Select2x2_toggled(button_pressed):
#	toggle_3x3_full.pressed = not button_pressed
	toggle_3x3_min.pressed = not button_pressed
	if button_pressed:
		template_size = TEMPLATE_SIZE_2x2
	else:
		template_size = TEMPLATE_SIZE_3x3
#	toggle_3x3_super.pressed = not button_pressed

func save_texture_png(path: String):
	out_texture.texture.get_data().save_png(path)

func _on_SaveTextureDialog_file_selected(path):
	save_texture_png(path)

func _on_HSlider_value_changed(value):
	display_slice(int(value - 1))
#	put_to_viewport(input_slices[int(value-1)][0][true], PI)

func _on_OptionButton_item_selected(_index):
	preprocess_input_image()

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
	var mask_out_vector: Array = []
	for mask in tile_masks:
		mask_out_vector.append("Vector2 ( %d, %d )" % [mask['position'].x, mask['position'].y])
		mask_out_vector.append(mask['godot_mask'])
	out_string += "0/name = \"0_0\"\n"
	out_string += "0/texture = ExtResource( 1 )\n"
	out_string += "0/tex_offset = Vector2( 0, 0 )\n"
	out_string += "0/modulate = Color( 1, 1, 1, 1 )\n"
	out_string += "0/region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += "0/tile_mode = 1\n"
	out_string += "0/autotile/bitmask_mode = 1\n"
	out_string += "0/autotile/bitmask_flags = %s\n" % str(mask_out_vector)
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

func _on_SaveTextureDialog2_file_selected(path: String):
	save_texture_png(path)
	var output_string : String
	print(export_type_select.pressed)
	if export_type_select.pressed:
		output_string = make_autotile_resource_data(path)
	else:
		output_string = make_manual_resource_data(path)
	var tileset_resource_path: String = path.get_basename( ) + ".tres"
#	var dir = Directory.new()
#	dir.remove(tileset_resource_path)
	var file = File.new()
	file.open(tileset_resource_path, File.WRITE)
	file.store_string(output_string)
	file.close()

func _on_AutotileSelect_toggled(button_pressed):
	description_select_box.visible = not button_pressed
