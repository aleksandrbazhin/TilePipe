extends Control


const SIZE := Vector2(68, 68)
const NEIGHBOUR_SIZE := 22
const NEIGHBOUR_SIZE_VEC := Vector2(NEIGHBOUR_SIZE, NEIGHBOUR_SIZE)
const SELF_OFFSET := NEIGHBOUR_SIZE_VEC
const DRAW_NEIGHBOUR_OFFSETS: Dictionary = {
	"CENTER": Vector2(NEIGHBOUR_SIZE, NEIGHBOUR_SIZE),
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

var rotations: Array


func setup(new_rotations: Array):
	rotations = new_rotations


func _draw():
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("32353d"))
	draw_rect(Rect2(SELF_OFFSET, NEIGHBOUR_SIZE_VEC), Const.HIGHLIGHT_COLORS[0])
	rect_min_size = SIZE
	if rotations.empty():
		return
	for i in Const.TILE_MASK.size():
		var part_name = Const.TILE_MASK.keys()[i]
		var angle_string := str(int(rotations[i]) * 90)
		var draw_position: Vector2 = DRAW_NEIGHBOUR_OFFSETS[part_name]
		draw_position.x += NEIGHBOUR_SIZE / 2.0 - angle_string.length() * 3
		draw_position.y += NEIGHBOUR_SIZE / 2.0 + 5
		for symbol in angle_string:
			var number_width := draw_char(font, draw_position, symbol, "0")
			draw_position.x += number_width 
