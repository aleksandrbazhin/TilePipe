extends TextureRect


const NEIGHBOUR_SIZE := 10
const TILE_BORDER := Vector2(1, 1)
const NEIGHBOUR_SIZE_VEC := Vector2(NEIGHBOUR_SIZE, NEIGHBOUR_SIZE)
const SELF_OFFSET := NEIGHBOUR_SIZE_VEC
const DRAW_NEIGHBOUR_OFFSETS: Dictionary = {
	"TOP": Vector2(NEIGHBOUR_SIZE, 0),
	"TOP_RIGHT": Vector2(NEIGHBOUR_SIZE * 2, 0),
	"RIGHT": Vector2(NEIGHBOUR_SIZE * 2, NEIGHBOUR_SIZE),
	"BOTTOM_RIGHT": Vector2(NEIGHBOUR_SIZE * 2, NEIGHBOUR_SIZE * 2),
	"BOTTOM": Vector2(NEIGHBOUR_SIZE, NEIGHBOUR_SIZE * 2),
	"BOTTOM_LEFT": Vector2(0, NEIGHBOUR_SIZE * 2),
	"LEFT": Vector2(0, NEIGHBOUR_SIZE),
	"TOP_LEFT": Vector2(0, 0),
}
const BG_COLOR := Color.white
const BG_TILE_COLOR := Color.white
const FG_COLOR := Color("#98c0ef")
const SELF_COLOR := Color("#b8e0ff")

var image_tiles_x_amount = 0
var data_len = 0
var tile_size := Vector2.ZERO
var texture_size := Vector2.ZERO


func _draw():
	draw_rect(Rect2(Vector2.ZERO, texture_size), BG_COLOR)
	for tile_index in range(data_len):
		var tile_row := int(tile_index / image_tiles_x_amount)
		var tile_col := int(tile_index - tile_row * image_tiles_x_amount)
		var tile_pos := Vector2(tile_col, tile_row)
		# background
		draw_rect(Rect2(tile_pos * tile_size + TILE_BORDER, tile_size - TILE_BORDER * 2), BG_TILE_COLOR)
		# center
		draw_rect(Rect2(tile_pos * tile_size + SELF_OFFSET + TILE_BORDER, NEIGHBOUR_SIZE_VEC), SELF_COLOR)
		var tile_mask: int = tile_index
		for neighbour_mask_name in Const.TILE_MASK:
			var check_bit: int = Const.TILE_MASK[neighbour_mask_name]
			var has_neighbour: bool = tile_mask & check_bit != 0
			if has_neighbour:
				var offset: Vector2 = DRAW_NEIGHBOUR_OFFSETS[neighbour_mask_name]
				var neigbour_pos := tile_pos * tile_size + offset + TILE_BORDER
				draw_rect(Rect2(neigbour_pos, NEIGHBOUR_SIZE_VEC), FG_COLOR)
