extends Control

class_name ScalableTextureContainer

var current_tile_size: Vector2
var is_ready := false

onready var bg_rect := $BGTextureRect
onready var texture_rect := $TextureRect
onready var size_label := $InputInfo/TileSizeLabel

func _ready():
	is_ready = true


func set_texture(texture: Texture, tile_size: Vector2 = Const.DEFAULT_TILE_SIZE):
	texture_rect.texture = texture
	current_tile_size = tile_size
#	set_input_tile_size(tile_size)


func set_input_tile_size(tile_size: Vector2):
	yield(get_tree(), "idle_frame")
	if texture_rect.texture == null:
		return
	var input_size: Vector2 = texture_rect.texture.get_size()
	var x_scale: float = texture_rect.rect_size.x / input_size.x
	var y_scale: float = texture_rect.rect_size.y / input_size.y
	var scale_factor: float = min(x_scale, y_scale)
	scale_factor = Helpers.snap_down_to_po2(scale_factor)
	texture_rect.rect_scale = Vector2(scale_factor, scale_factor)
	var bg_scale :=  scale_factor * tile_size / Const.DEFAULT_TILE_SIZE
	bg_rect.rect_size = texture_rect.rect_size / bg_scale
	bg_rect.rect_scale = bg_scale
	size_label.text = "Tile size: %dx%dpx" % [tile_size.x, tile_size.y]


func _draw():
	#TODO: redraws 2 times instead of one
	if is_ready:
		set_input_tile_size(current_tile_size)
