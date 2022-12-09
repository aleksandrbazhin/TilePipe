class_name ResultFrameView
extends TextureRect


signal subtile_selected(position, frame_index)

onready var subtile_highlight := $SubtileHighlight
onready var subtile_selection := $SubtileSelection
onready var label := $Label

var frame_index := 0

var _tile_size: Vector2
var _subtile_spacing: Vector2

var _scale := Vector2.ONE
var _selected_index := Vector2.ZERO
var _highlighted_index := Vector2.ZERO


func setup_highlights(tile_size: Vector2, subtile_spacing: Vector2, 
		subtile_index: Vector2, new_frame_index: int):
	_tile_size = tile_size
	_subtile_spacing = subtile_spacing
	frame_index = new_frame_index
	subtile_highlight.rect_size = tile_size
	subtile_selection.rect_size = tile_size


func _on_ResultTextureViewRect_gui_input(event: InputEvent):
	if not event is InputEventMouseButton and not event is InputEventMouseMotion:
		return
#	var texture_size: Vector2 = texture.get_size() 
	var texture_size: Vector2 = rect_min_size
	if event.position.x >= texture_size.x or \
			event.position.y >= texture_size.y or \
			event.position.x < 0 or event.position.y < 0:
		return
	var subtile_index: Vector2 = (event.position / (_tile_size + _subtile_spacing) / _scale).floor()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		select_subtile(subtile_index)
	elif event is InputEventMouseMotion:
		highlight_subtile(subtile_index)


func clear_subtile_overlays(clear_highlights: bool, clear_selections: bool):
	if clear_selections:
		subtile_selection.hide()
		_selected_index = Vector2.ZERO
	if clear_highlights:
		subtile_highlight.hide()
		_highlighted_index = Vector2.ZERO


func select_subtile(subtile_index: Vector2):
	_selected_index = subtile_index
	subtile_selection.show()
	var subtile_position = calculate_subtile_position(_tile_size, _subtile_spacing, subtile_index)
	if subtile_selection.rect_position != subtile_position:
		subtile_selection.rect_position = subtile_position
	emit_signal("subtile_selected", subtile_index, frame_index)


func highlight_subtile(subtile_index: Vector2):
	_highlighted_index = subtile_index
	subtile_highlight.show()
	var subtile_position = calculate_subtile_position(_tile_size, _subtile_spacing, subtile_index)
	if subtile_highlight.rect_position != subtile_position:
		subtile_highlight.rect_position = subtile_position


func calculate_subtile_position(tile_size: Vector2, spacing: Vector2, index: Vector2) -> Vector2:
	return index * (tile_size + spacing) * _scale


func set_current_scale(current_scale: Vector2, is_selected: bool):
	_scale = current_scale
	rect_min_size = texture.get_size() * _scale
	subtile_highlight.rect_scale = _scale
	subtile_selection.rect_scale = _scale
	subtile_selection.rect_position = calculate_subtile_position(_tile_size, _subtile_spacing, _selected_index)
	subtile_highlight.rect_position = subtile_selection.rect_position
	label.hide()
	yield(VisualServer, "frame_post_draw")
	var y = (rect_min_size.y + $Label.rect_size.x) / 2.0
	label.rect_position.y =  y 
	label.show()

func set_frame_index(index: int):
	frame_index = index
	$Label.text = "Frame " + str(frame_index + 1)
