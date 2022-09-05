extends Control


const SIZE := Vector2(68, 68)
const NEIGHBOUR_SIZE := 22
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
const font := preload("res://assets/styles/subscribe_font.tres")

var flips_x: Array
var flips_y: Array


func setup(new_flips_x: Array, new_flips_y: Array):
	flips_x = new_flips_x
	flips_y = new_flips_y


func _draw():
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("32353d"))
	draw_rect(Rect2(SELF_OFFSET, NEIGHBOUR_SIZE_VEC), Const.HIGHLIGHT_COLORS[0])
	rect_min_size = SIZE
	if flips_x.empty() or flips_y.empty():
		return
	for i in Const.TILE_MASK.size():
		var flip_string := ""
		if flips_x[i]:
			flip_string += "x"
		if flips_y[i]:
			flip_string += "y"
		var draw_position: Vector2 = DRAW_NEIGHBOUR_OFFSETS[Const.TILE_MASK.keys()[i]]
		draw_position.x += NEIGHBOUR_SIZE / 2.0 - flip_string.length() * 3
		draw_position.y += NEIGHBOUR_SIZE / 2.0 + 5
		for symbol in flip_string:
			var number_width := draw_char(font, draw_position, symbol, "0")
			draw_position.x += number_width 
