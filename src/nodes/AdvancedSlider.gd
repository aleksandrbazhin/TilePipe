extends HSlider

class_name AdvancedSlider

# this file exists only because Godot "editable" implementation is bugged for sliders
# they are tied to the mouse if set not editable during click callback

var MAX: float = 0.5


signal released(value)


func _gui_input(event):
	if (event is InputEventMouseButton) && !event.pressed && (event.button_index == BUTTON_LEFT):
		emit_signal("released", value)


func quantize(levels: int):
	var safe_levels = max(levels, 1)
	step = MAX / float(safe_levels)
	tick_count = safe_levels + 1
	value = step * round(value / step)
