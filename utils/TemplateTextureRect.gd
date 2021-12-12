extends TextureRect

const TILE_SIZE := Vector2(64, 64)
const NEIGHBOUR_SIZE := 20
const NEIGHBOUR_SIZE_VEC := Vector2(NEIGHBOUR_SIZE, NEIGHBOUR_SIZE)
const SELF_OFFSET := Vector2(NEIGHBOUR_SIZE + 2, NEIGHBOUR_SIZE + 2)
const DRAW_NEIGHBOUR_OFFSETS: Dictionary = {
	"TOP": Vector2(NEIGHBOUR_SIZE + 2, 1),
	"TOP_RIGHT": Vector2(NEIGHBOUR_SIZE * 2 + 3, 1),
	"RIGHT": Vector2(NEIGHBOUR_SIZE * 2 + 3, NEIGHBOUR_SIZE + 2),
	"BOTTOM_RIGHT": Vector2(NEIGHBOUR_SIZE * 2 + 3, NEIGHBOUR_SIZE * 2 + 3),
	"BOTTOM": Vector2(NEIGHBOUR_SIZE + 2, NEIGHBOUR_SIZE * 2 + 3),
	"BOTTOM_LEFT": Vector2(1, NEIGHBOUR_SIZE * 2 + 3),
	"LEFT": Vector2(1, NEIGHBOUR_SIZE + 2),
	"TOP_LEFT": Vector2(1, 1),
}
const BG_COLOR := Color.darkgray
const BG_TILE_COLOR := Color.white
const FG_COLOR := Color.dodgerblue
const SELF_COLOR := Color.royalblue

var data: Dictionary
var image_tiles_x_amount = 8


func _draw():
	if not data.empty():
		var data_len = data["data"].size()
		var texture_size = TILE_SIZE * Vector2(image_tiles_x_amount, ceil(data_len / image_tiles_x_amount))
		rect_size = texture_size
		draw_rect(Rect2(Vector2.ZERO, texture_size), BG_COLOR)

		var tile_index = 0
		for tile_data in data["data"]:
			var tile_row := int(tile_index / image_tiles_x_amount)
			var tile_col := int(tile_index - tile_row * image_tiles_x_amount)
			var tile_pos := Vector2(tile_col, tile_row)
			var tile_mask: int = int(tile_data["mask_variants"][0])
			
			draw_rect(Rect2(tile_pos * TILE_SIZE + Vector2(1, 1), TILE_SIZE - Vector2(2, 2)), BG_TILE_COLOR)
			draw_rect(Rect2(tile_pos * TILE_SIZE + SELF_OFFSET, NEIGHBOUR_SIZE_VEC), SELF_COLOR)
			
			for neighbour_mask_name in Const.TILE_MASK:
				var check_bit: int = Const.TILE_MASK[neighbour_mask_name]
				var has_neighbour: bool = tile_mask & check_bit != 0
				if has_neighbour:
					var offset: Vector2 = DRAW_NEIGHBOUR_OFFSETS[neighbour_mask_name]
					var neigbour_pos := tile_pos * TILE_SIZE + offset
					draw_rect(Rect2(neigbour_pos, NEIGHBOUR_SIZE_VEC), FG_COLOR)
#					print(tile_mask, " ", neighbour_mask_name)
			tile_index += 1



func draw_data(new_data: Dictionary):
	print("up!")
	data = new_data
	update()
