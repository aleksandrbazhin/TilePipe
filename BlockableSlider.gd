extends HSlider

const MAX: float = 0.5
const MAX_TICKS: int = 17

signal released(value)

func _gui_input(event):
	if (event is InputEventMouseButton) && !event.pressed && (event.button_index == BUTTON_LEFT):
		emit_signal("released", value)

func quantize(levels: int):
	step = MAX / float(levels)
	tick_count = levels + 1
	value = step * round(value / step)
