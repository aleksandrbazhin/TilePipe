class_name FramePartsRowControl
extends CenterContainer


signal toggled(is_enabled)

var is_silenced := false


func set_enabled_quietly(is_enabled: bool):
	is_silenced = true
	$CheckBox.pressed = is_enabled
	is_silenced = false


func _on_CheckBox_toggled(button_pressed: bool):
	if not is_silenced:
		emit_signal("toggled", button_pressed)


func block():
	$CheckBox.disabled = true
