class_name AdvancedCheckButton
extends CheckButton


signal toggled_no_silence(button_pressed)

var is_silenced: bool = false


func _ready():
	connect("toggled", self, "_on_AdvancedCheckButton_toggled")


func set_toggled_quietly(button_pressed: bool):
	is_silenced = true
	pressed = button_pressed
	is_silenced = false



func _on_AdvancedCheckButton_toggled(button_pressed):
	if not is_silenced:
		emit_signal("toggled_no_silence", button_pressed)
