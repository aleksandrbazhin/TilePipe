extends ColorRect

class_name TileMaskPreview

const SIZE := Vector2(68, 68)
const BG_TILE_COLOR := Color("edf5ff")
const FG_COLOR := Color("98c0ef")
const SELF_COLOR := Color("b8e0ff")
const NEIGHBOUR_SIZE := 22
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

var mask_value: int 


func _init(new_mask_value: int):
	mask_value = new_mask_value


func _draw():
	draw_rect(Rect2(TILE_BORDER, SIZE - TILE_BORDER * 2), BG_TILE_COLOR)
	draw_rect(Rect2(SELF_OFFSET + TILE_BORDER, NEIGHBOUR_SIZE_VEC), SELF_COLOR)
	rect_min_size = SIZE
	for neighbour_mask_name in Const.TILE_MASK:
		var check_bit: int = Const.TILE_MASK[neighbour_mask_name]
		var has_neighbour: bool = mask_value & check_bit != 0
		if has_neighbour:
			var offset: Vector2 = DRAW_NEIGHBOUR_OFFSETS[neighbour_mask_name]
			var neigbour_pos := offset + TILE_BORDER
			draw_rect(Rect2(neigbour_pos, NEIGHBOUR_SIZE_VEC), FG_COLOR)
