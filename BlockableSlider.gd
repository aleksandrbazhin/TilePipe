extends HSlider

signal released(value)

func _gui_input(event):
	if (event is InputEventMouseButton) && !event.pressed && (event.button_index == BUTTON_LEFT):
		emit_signal("released", value)
