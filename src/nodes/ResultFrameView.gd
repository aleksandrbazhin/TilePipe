class_name ResultFrameView
extends TextureRect


signal subtile_selected(position, frame_index)

onready var subtile_highlight := $SubtileHighlight
onready var subtile_selection := $SubtileSelection

var _tile_size: Vector2
var _subtile_spacing: Vector2
var _frame_index := 0
var is_focused := false


func setup_highlights(tile_size: Vector2,  subtile_spacing: Vector2, subtile_index: Vector2, frame_index: int):
	_tile_size = tile_size
	_subtile_spacing = subtile_spacing
	_frame_index = frame_index
	subtile_highlight.rect_size = tile_size
	subtile_selection.rect_size = tile_size


func _on_ResultTextureViewRect_gui_input(event: InputEvent):
	if not event is InputEventMouseButton and not event is InputEventMouseMotion:
		return
	var texture_size: Vector2 = texture.get_size() 
	if event.position.x >= texture_size.x or \
			event.position.y >= texture_size.y or \
			event.position.x < 0 or event.position.y < 0:
		return
	var subtile_index: Vector2 = (event.position / (_tile_size + _subtile_spacing)).floor()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		select_subtile(subtile_index)
	elif event is InputEventMouseMotion:
		highlight_subtile(subtile_index)


func clear_subtile_overlays(clear_highlights: bool, clear_selections: bool):
	if clear_selections:
		subtile_selection.hide()
	if clear_highlights:
		subtile_highlight.hide()


func select_subtile(subtile_index: Vector2):
	subtile_selection.show()
	var subtile_position = calculate_subtile_position(_tile_size, _subtile_spacing, subtile_index)
	if subtile_selection.rect_position != subtile_position:
		subtile_selection.rect_position = subtile_position
	emit_signal("subtile_selected", subtile_index, _frame_index)


func highlight_subtile(subtile_index: Vector2):
	subtile_highlight.show()	
	var subtile_position = calculate_subtile_position(_tile_size, _subtile_spacing, subtile_index)
	if subtile_highlight.rect_position != subtile_position:
		subtile_highlight.rect_position = subtile_position


func calculate_subtile_position(tile_size: Vector2, spacing: Vector2, index: Vector2) -> Vector2:
	return index * (tile_size + spacing)


