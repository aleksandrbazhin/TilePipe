class_name ScaleControls
extends HBoxContainer


signal scale_changed(scale)

export var exponent: float = 1.5
var _max_scale: float = pow(exponent, 5.0)
var _min_scale: float = 1.0 / pow(exponent, 5.0)
var _scale: float = 1.0 


func reset():
	_scale = 1.0
	emit_signal("scale_changed", _scale)


func get_current_scale() -> float:
	return _scale


func set_current_scale(scale: float):
	_scale = clamp(scale, _min_scale, _max_scale)
	$Label.text = str(int(100.0 * _scale)) + "%"
	emit_signal("scale_changed", _scale)


func increase_scale():
	set_current_scale(_scale * exponent)


func decrease_scale():
	set_current_scale(_scale / exponent)


func _on_PlusScaleButton_pressed():
	increase_scale()


func _on_MinusScaleButton_pressed():
	decrease_scale()

func _unhandled_key_input(event: InputEventKey):
	if not event.is_pressed():
		return
#	if get_focus_owner() != get_line_edit():
#		return
	match event.scancode:
		KEY_PLUS, KEY_EQUAL, KEY_KP_ADD:
			increase_scale()
		KEY_MINUS, KEY_KP_SUBTRACT:
			decrease_scale()
