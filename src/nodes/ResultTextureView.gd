extends TextureRect

class_name ResultTextureView

signal mouse_motion(position)
signal mouse_click(position)


func _on_ResultTextureViewRect_gui_input(event: InputEvent):
	if not event is InputEventMouseButton and not event is InputEventMouseMotion:
		return
	var texture_size: Vector2 = texture.get_size() 
	if event.position.x >= texture_size.x or \
			event.position.y >= texture_size.y or \
			event.position.x < 0 or event.position.y < 0:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		emit_signal("mouse_click", event.position)
	elif event is InputEventMouseMotion:
		emit_signal("mouse_motion", event.position)



#func _on_TextureRect_gui_input(event: InputEvent):
#	if not event is InputEventMouseButton and not event is InputEventMouseMotion:
#		return
#	var texture_size: Vector2 = result_texture.texture.get_size() 
#	if event.position.x >= texture_size.x or \
#			event.position.y >= texture_size.y or \
#			event.position.x < 0 or event.position.y < 0:
#		return
#	var subtile_index: Vector2 = (event.position / (current_output_tile_size + tile.subtile_spacing)).floor()
#	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
#		select_subtile(subtile_index)
#	elif event is InputEventMouseMotion:
#		highlight_subtile(calculate_subtile_position(subtile_index, tile.subtile_spacing))
#
