# the class to hold the data from a generated tile
extends Resource

class_name GeneratedTile

var mask: int
var position_in_template: Vector2
var image: Image = null
var is_rendering := false


func _init(new_mask: int, new_position_in_template: Vector2):
	._init()
	mask = new_mask
	position_in_template = new_position_in_template


func capture_texture(texture: Texture, output_tile_size: Vector2, smoothing: bool = false):
	var input_tile_size := texture.get_size()
	var resize_factor: float = float(output_tile_size.x) / float(input_tile_size.x)
	image = Image.new()
	image.create(int(input_tile_size.x), int(input_tile_size.y), false, Image.FORMAT_RGBA8)
	image.blit_rect(
		texture.get_data(),
		Rect2(Vector2.ZERO, input_tile_size), 
		Vector2.ZERO)
	if resize_factor != 1.0:
		var interpolation: int = Image.INTERPOLATE_NEAREST if not smoothing else Image.INTERPOLATE_TRILINEAR
		image.resize(int(output_tile_size.x), int(output_tile_size.y), interpolation)
	is_rendering = false
