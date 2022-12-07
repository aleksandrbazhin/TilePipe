class_name AdvancedSpinBox
extends SpinBox

# this signal is only emitted when triggered by not a quie
signal value_changed_no_silence(value)

var is_silenced: bool = false


#func _unhandled_key_input(event: InputEventKey):
#	if not event.is_pressed() or get_focus_owner() != get_line_edit():
#		return
#	match event.scancode:
#		KEY_UP:
#			value += 1
#		KEY_DOWN:
#			value -= 1


# trying to prevent default behavior(focus change)
func _input(event: InputEvent):
	if not event is InputEventKey:
		return
	if not  event.is_pressed():
		return
	if get_focus_owner() != get_line_edit():
		return
	if not (event.scancode == KEY_UP or event.scancode == KEY_DOWN):
		return
	if get_line_edit().editable:
		if event.scancode == KEY_UP:
			value += 1
		else:
			value -= 1
	get_tree().set_input_as_handled()


func set_value_quietly(new_value: float):
	is_silenced = true
	value = new_value
	is_silenced = false


func _on_AdvancedSpinBox_value_changed(value):
	if not is_silenced:
		emit_signal("value_changed_no_silence", value)


func remove(_param1 = null, _param2 = null):
	queue_free()
