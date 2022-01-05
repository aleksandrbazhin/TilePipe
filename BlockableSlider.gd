extends HSlider

# this file exists only because Godot "editable" implementation is bugged for sliders
# they are tied to the mouse if set not editable during click callback

var MAX: float = 0.5


signal released(value)


func _gui_input(event):
	if (event is InputEventMouseButton) && !event.pressed && (event.button_index == BUTTON_LEFT):
		emit_signal("released", value)


func quantize(levels: int):
	step = MAX / float(levels)
	tick_count = levels + 1
	value = step * round(value / step)
