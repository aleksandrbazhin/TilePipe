class_name PartFrameControl
extends TextureRect


signal part_frequency_click(part)

const RANDOM_ICON_POSITION := Vector2(4, 6)
const FRAME_ICON_POSITION := Vector2(4, 26)
const BG_COLOR := Color(0.09, 0.14, 0.18, 0.6)

var part_type: int = Ruleset.RULESET_TILE_PARTS.FULL
var random_variant: int = 0
var random_frequency: int = 1 
var frame_index: int = 0

var max_frames: int = 1
var part_ref: WeakRef

onready var random_label: Label = $RandomLabel
onready var frame_label: Label = $FrameLabel

func setup(new_part_type: int, part: TilePart, new_random_frequency: int = 1):
#		new_animation_frame: int = 1, new_max_frames: int = 1):
	part_type = new_part_type
	part_ref = weakref(part)
	random_variant = part.variant_index
	random_frequency = new_random_frequency
#	animation_frame = new_animation_frame
#	max_frames = new_max_frames
	var itex := ImageTexture.new()
	itex.create_from_image(part)
	itex.set_size_override(rect_size)
	texture = itex
#	texture = Ruleset.RULESET_PART_TEXTURES[part_type]


func _ready():
	draw_labels()


func get_part_variant_index() -> int:
	var result := 0
	if part_ref != null:
		var part: TilePart = part_ref.get_ref()
		result = part.variant_index
	return result


func set_part_frame(frame_idx: int):
	if part_ref != null:
		var part: TilePart = part_ref.get_ref()
		if frame_idx > 0:
			random_variant = 0
			part.is_used_for_random = false
			frame_index = frame_idx
		else:
			frame_index = 0
			random_variant = part.variant_index
			part.is_used_for_random = true


func draw_labels():	
	hint_tooltip = "Part variant " + str(random_variant + 1) + " with frequency " + str(random_frequency) \
		+ "\nUsed on the frame " + str(frame_index + 1)
	random_label.text = str(random_variant + 1) + "x" + str(random_frequency)
	frame_label.text = str(frame_index + 1)


func update_info():

#	var used_for_random := true
#	if part_ref != null:
#		var part: TilePart = part_ref.get_ref()
#		if part != null:
#			used_for_random = part.is_used_for_random
#	if used_for_random:
##		random_label.show()
##		frame_label.hide()
#		random_label.text = str(random_variant + 1) + "x" + str(random_frequency)
#	else:
##		random_label.hide()
##		frame_label.show()
#		frame_label.text = str(frame_index + 1)
	draw_labels()
	update()


func _draw():
#	var used_for_random := true
#	if part_ref != null:
#		var part: TilePart = part_ref.get_ref()
#		if part != null:
#			used_for_random = part.is_used_for_random
#	draw_rect(Rect2(Vector2.ZERO, rect_size), BG_COLOR)
#	if used_for_random:
#		draw_texture(preload("res://assets/images/random.png"), RANDOM_ICON_POSITION)
#	else:
#		draw_texture(preload("res://assets/images/frames.png"), FRAME_ICON_POSITION)
	draw_rect(Rect2(Vector2.ZERO, rect_size), BG_COLOR)
	draw_texture(preload("res://assets/images/random.png"), RANDOM_ICON_POSITION)
	draw_texture(preload("res://assets/images/frames.png"), FRAME_ICON_POSITION)


func _on_PartFrameControl_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("part_frequency_click", self)
