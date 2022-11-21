class_name PartFrameControl
extends TextureRect


signal part_frequency_click(part)


#const RANDOM_ICON_POSITION := Vector2(4, 6)
const RANDOM_ICON_POSITION := Vector2(4, 28)
const FRAME_ICON_POSITION := Vector2(4, 26)
const BG_COLOR := Color(0.3, 0.4, 0.4, 0.5)


# TODO: если нет рандомизации (макс рандом ные варианты == 1), то писать No вместо рандом лейбла
# TODO: делить на 2 все варианты при выборе количества фреймов
# TODO: переделать контрол со скролла на spinbox

var part_type: int = Ruleset.RULESET_TILE_PARTS.FULL
var random_variant: int = 0
var random_priority: int = 1 
var frame_index: int = 0
var total_random_priority: int = 1
var max_frames: int = 1
var part_ref: WeakRef

onready var random_label: Label = $RandomLabel
onready var frame_label: Label = $FrameLabel


func setup(new_part_type: int, part: TilePart, new_random_priority: int = 1, new_total_prority: int = 1):
	
	part_type = new_part_type
	part_ref = weakref(part)
	random_variant = part.variant_index
	random_priority = new_random_priority
	total_random_priority = new_total_prority
	var itex := ImageTexture.new()
	itex.create_from_image(part, 0)
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


func draw_labels():	
	hint_tooltip = "Part variant " + str(random_variant + 1) + " with randomization priority: " + str(random_priority) 
	random_label.text = str(random_priority) + "/" + str(total_random_priority)  


func update_info():
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
#	draw_texture(preload("res://assets/images/frames.png"), FRAME_ICON_POSITION)


func _on_PartFrameControl_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("part_frequency_click", self)
