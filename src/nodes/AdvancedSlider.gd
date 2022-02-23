extends HSlider

class_name AdvancedSlider

# this file exists only because Godot "editable" implementation is bugged for sliders
# they are tied to the mouse if set not editable during click callback

const MAX: float = 0.5
const FONT := preload("res://assets/styles/subscribe_font.tres")
const LABEL_DRAW_Y := 27
const CHAR_WIDTH_ESTIMATE := 4.25

signal released(value)


func _gui_input(event):
	if (event is InputEventMouseButton) && !event.pressed && (event.button_index == BUTTON_LEFT):
		emit_signal("released", value)


func quantize(levels: int):
	var safe_levels = max(levels, 1)
	step = MAX / float(safe_levels)
	tick_count = safe_levels + 1
	value = step * round(value / step)


func draw_word(word: String, draw_position: Vector2):
	for symbol in word:
		var number_width := draw_char(FONT, draw_position, symbol, "0")
		draw_position.x += number_width 


func _draw():
	draw_char(FONT, Vector2(5, LABEL_DRAW_Y), "0", "0")
	var end_label := str(tick_count - 1)
	draw_word(end_label, Vector2(
		rect_size.x - end_label.length() * CHAR_WIDTH_ESTIMATE - 5, 
		LABEL_DRAW_Y))
	if value != max_value and value != min_value:
		var value_label := str(int(value * 2.0 * (tick_count - 1)))
		draw_word(value_label, Vector2(
			9 + (rect_size.x - 14) * value * 2.0 - value_label.length() * CHAR_WIDTH_ESTIMATE, 
			LABEL_DRAW_Y))
