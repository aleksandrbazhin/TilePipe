class_name AdvancedSpinBox
extends SpinBox


func _input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and \
			(event.scancode == KEY_UP or event.scancode == KEY_DOWN):
		if get_focus_owner() == get_line_edit():
			if get_line_edit().editable:
				if event.scancode == KEY_UP:
					value += 1
				else:
					value -= 1
			get_tree().set_input_as_handled()
