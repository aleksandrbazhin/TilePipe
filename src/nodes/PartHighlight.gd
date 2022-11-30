class_name PartHighlight
extends Control


signal focused()
signal unfocused()

var id: int = -1

onready var panel := $Panel
onready var label := $Panel/Label


func set_hightlight_universal_size(size: Vector2):
	rect_size = size
	$Border.rect_size = size
	$Panel.rect_position.y = size.y - 13
	$Panel.rect_position.x = size.x - 18
	$Panel.rect_min_size.x = 16


# [only after ready]
func set_id(new_id: int, inside: bool = false):
	var color_index := (new_id - 1) % Const.HIGHLIGHT_COLORS.size()
	if inside:
		panel.rect_position.y = 35
	if id == -1:
		id = new_id
		label.text = str(id)
		set_border_hew(color_index)
		set_label_hew(color_index, panel)
	else:
		var last_label_panel = get_child(get_child_count() - 1)
		var new_label: Panel = last_label_panel.duplicate(DUPLICATE_USE_INSTANCING)
		add_child(new_label)
		set_label_hew(color_index, new_label)
		new_label.get_node("Label").text = str(new_id)
		new_label.rect_position.x -= 16
		if new_label.rect_position.x < 0:
			new_label.rect_position.x = rect_size.x - 15
			new_label.rect_position.y = rect_size.y - 13


func set_border_hew(color_index: int):
	$Border.self_modulate = Const.HIGHLIGHT_COLORS[color_index]
	

func set_label_hew(color_index: int, label_panel: Panel):
	label_panel.self_modulate = Const.HIGHLIGHT_COLORS[color_index]


func _on_TileHighlight_mouse_entered():
	modulate = Color("aaaaaa")
	emit_signal("focused", self)


func _on_TileHighlight_mouse_exited():
	modulate = Color("ffffff")
	emit_signal("unfocused", self)
