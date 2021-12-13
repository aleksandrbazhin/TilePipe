extends ViewportContainer

const TILES_X = 20
const DATA_LEN = 256
const TILE_SIZE := Vector2(32, 32)

var data: Dictionary


onready var texture_node: TextureRect = $Viewport/TemplateTextureRect

func get_texture() -> ViewportTexture:
	return $Viewport.get_texture()


func draw_data(new_data: Dictionary):
	data = new_data
	
# warning-ignore:integer_division
	var texture_size_tiles: Vector2 = Vector2(TILES_X, floor(DATA_LEN / TILES_X))
	if texture_size_tiles.y * texture_size_tiles.x < DATA_LEN:
		texture_size_tiles.y += 1
	var texture_size := TILE_SIZE * texture_size_tiles
	rect_size = texture_size
	rect_min_size = texture_size
	$Viewport.size = texture_size
	
	texture_node.texture_size = texture_size
	texture_node.rect_size = texture_size
	texture_node.rect_min_size = texture_size
	texture_node.tile_size = TILE_SIZE
	texture_node.data_len = DATA_LEN
	texture_node.image_tiles_x_amount = TILES_X
	
	texture_node.update()
