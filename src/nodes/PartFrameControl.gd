class_name PartFrameControl
extends TextureRect


const RANDOM_ICON_POSITION := Vector2(4, 6)
const FRAME_ICON_POSITION := Vector2(4, 26)
const BG_COLOR := Color(0.05, 0.12, 0.18, 0.75)

var part_type: int = Ruleset.RULESET_TILE_PARTS.FULL
var random_variant: int = 0
var random_frequency: int = 1 
var animation_frame: int = 1
var max_frames: int = 1


func setup(new_part_type: int = Const.RULESET_TILE_PARTS.FULL, new_random_variant: int = 0, 
		new_random_frequency: int = 1, new_animation_frame: int = 1, new_max_frames: int = 1):
	part_type = new_part_type
	random_variant = new_random_variant
	random_frequency = new_random_frequency
	animation_frame = new_animation_frame
	max_frames = new_max_frames
	texture = Ruleset.RULESET_PART_TEXTURES[part_type]


func _ready():
	$RandomLabel.text = str(random_variant + 1) + "x" + str(random_frequency)
	$AnimationLabel.text = str(animation_frame)


func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_size), BG_COLOR)
	draw_texture(preload("res://assets/images/random.png"), RANDOM_ICON_POSITION)
	draw_texture(preload("res://assets/images/frames.png"), FRAME_ICON_POSITION)
