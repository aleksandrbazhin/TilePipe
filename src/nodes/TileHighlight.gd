extends Control

class_name TileHighlight

var id: int = -1


func set_id(new_id: int):
	var color_index := (new_id - 1) % Const.HIGHLIGHT_COLORS.size()
	if id == -1:
		id = new_id
		$Panel/Label.text = str(id)
		$Panel/Label.text = str(new_id)
		set_border_hew(color_index)
		set_label_hew(color_index, $Panel)
		show()
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
#		new_label.rect_position.x -= 16
#		if new_label.rect_position.x < 0:
#			new_label.margin_left = -15
#			new_label.margin_bottom = 0
#		new_label.rect_size = last_label_panel.rect_size


func set_border_hew(color_index: int):
	$Border.self_modulate = Const.HIGHLIGHT_COLORS[color_index]
	

func set_label_hew(color_index: int, label_panel: Panel):
	label_panel.self_modulate = Const.HIGHLIGHT_COLORS[color_index]


#func set_hew_by_id(new_id: int, set_border: bool = true):
#	var color_index := (new_id - 1) % COLORS.size()
#	$Panel.self_modulate = COLORS[color_index]
#	if set_border:
#		$Border.self_modulate = COLORS[color_index]

	


func _on_TileHighlight_mouse_entered():
	modulate = Color("aaaaaa")


func _on_TileHighlight_mouse_exited():
	modulate = Color("ffffff")
