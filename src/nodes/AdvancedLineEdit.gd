class_name AdvancedLineEdit
extends LineEdit


signal text_changed_no_silence(new_text)

var is_silenced: bool = false


func _ready():
	connect("text_entered", self, "_on_AdvancedLineEdit_text_changed")


func set_text_quietly(new_text: String):
	is_silenced = true
	text = new_text
	is_silenced = false


func _on_AdvancedLineEdit_text_changed(new_text):
	if not is_silenced:
		emit_signal("text_changed_no_silence", new_text)
