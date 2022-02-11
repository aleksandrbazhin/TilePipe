extends Control

var parts: Array

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

func setup(new_parts: Array):
	parts = new_parts

func _draw():
	draw_rect(Rect2(SELF_OFFSET, NEIGHBOUR_SIZE_VEC), Const.HIGHLIGHT_COLORS[0])
	rect_min_size = SIZE
	if parts.empty():
		return
	for i in Const.TILE_MASK.size():
		var part_name = Const.TILE_MASK.keys()[i]
		var part_index: int = int(parts[i]) % Const.HIGHLIGHT_COLORS.size()
		var draw_position: Vector2 = DRAW_NEIGHBOUR_OFFSETS[part_name]
		draw_rect(Rect2(draw_position, NEIGHBOUR_SIZE_VEC), Const.HIGHLIGHT_COLORS[part_index])
		var number_string := str(part_index + 1)
		draw_position.x += NEIGHBOUR_SIZE / 2.0 - number_string.length() * 3
		draw_position.y += NEIGHBOUR_SIZE / 2.0 + 4
		for number in number_string:
			var number_width := draw_char(font, draw_position, number, "0")
			draw_position.x += number_width 
