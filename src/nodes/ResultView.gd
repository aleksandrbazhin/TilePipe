class_name ResultView
extends ColorRect


export var single_tile_visible := true
export var controls_visible := true

var last_selected_subtile_index := Vector2.ZERO
var current_output_tile_size: Vector2

onready var selected_subtile_container := $VBoxContainer/HSplitContainer/SingleTile
onready var selected_subtile_texture := $VBoxContainer/HSplitContainer/SingleTile/SubtileTexture
#onready var result_texture: TextureRect = $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect
onready var result_texture_container: = $VBoxContainer/HSplitContainer/Result/TextureContainer/VBoxContainer
#onready var subtile_highlight := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect/SubtileHighlight
#onready var subtile_selection := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect/SubtileSelection
onready var bitmask_label := $VBoxContainer/HSplitContainer/SingleTile/BitmaskLabel


func render_from_tile(tile: TPTile, frame_index: int = 0):
#	var frame: TPTileFrame = tile.frames[frame_index]
	for frame in tile.frames:
#	print(frame)
		current_output_tile_size = tile.output_tile_size if tile.output_resize else tile.input_tile_size
		var subtiles_by_bitmasks: Dictionary = frame.result_subtiles_by_bitmask
	##		set_output_texture(null)
	#	for child in result_texture_container.get_children():
	#		child.queue_free()
		if subtiles_by_bitmasks.empty():
			return
		var out_image := Image.new()
		var out_image_size: Vector2 = tile.template_size * current_output_tile_size
		out_image_size += (tile.template_size - Vector2.ONE) * tile.subtile_spacing
		out_image.create(int(out_image_size.x), int(out_image_size.y), false, Image.FORMAT_RGBA8)
		var tile_rect := Rect2(Vector2.ZERO, current_output_tile_size)
		var itex = ImageTexture.new()
		itex.create_from_image(out_image, 0)
		for mask in subtiles_by_bitmasks.keys():
			for tile_variant_index in range(subtiles_by_bitmasks[mask].size()):
				var subtile: GeneratedSubTile = subtiles_by_bitmasks[mask][tile_variant_index]
				var tile_position: Vector2 = subtile.position_in_template * current_output_tile_size
				tile_position +=  subtile.position_in_template * tile.subtile_spacing
				if subtile.image == null:
					continue
				out_image.blit_rect(subtile.image, tile_rect, tile_position)
				itex.set_data(out_image)
		append_output_texture(itex)
		frame.set_result_texture(itex)
		#	tile.output_texture = itex
	#		if result_texture_container.get_child_count() > 0:
	#			subtile_highlight.rect_size = current_output_tile_size
	#			subtile_highlight.show()
	#			subtile_selection.rect_size = current_output_tile_size
	#			subtile_selection.show()
	#			highlight_subtile(Vector2.ZERO)
	#			if not last_selected_subtile_index in frame.parsed_template:
	#				last_selected_subtile_index = Vector2.ZERO
	#			select_subtile(last_selected_subtile_index)


func append_output_texture(texture: Texture):
	var result_texture_view := preload("res://src/nodes/ResultTextureView.tscn").instance()
	result_texture_view.texture = texture
	if result_texture_view != null:
		var image_size: Vector2 = result_texture_view.texture.get_size()
		result_texture_view.rect_size = image_size
	result_texture_container.add_child(result_texture_view)


func clear():
	bitmask_label.text = ""
	for child in result_texture_container.get_children():
		child.queue_free()
	last_selected_subtile_index = Vector2.ZERO
	select_subtile(last_selected_subtile_index)
	highlight_subtile(Vector2.ZERO)


func highlight_subtile(subtile_position: Vector2):
	pass
#	if subtile_highlight.rect_position != subtile_position:
#
#		subtile_highlight.rect_position = subtile_position


func calculate_subtile_position(index: Vector2, spacing: Vector2) -> Vector2:
	return index * (current_output_tile_size + spacing)


func select_subtile(subtile_index: Vector2, frame_index: int = 0):
	var subtile_position := Vector2.ZERO
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		selected_subtile_texture.texture = null
		return
	if not subtile_index in tile.frames[frame_index].parsed_template:
		selected_subtile_texture.texture = null
		return
	if result_texture_container.get_child_count() > 0:
		selected_subtile_texture.texture = null
		return
#	var subtile_ref: WeakRef = tile.frames[frame_index].parsed_template[subtile_index]
#	subtile_position = calculate_subtile_position(subtile_index, tile.subtile_spacing)
#	if subtile_selection.rect_position != subtile_position:
#		subtile_selection.rect_position = subtile_position
#	if subtile_ref == null:
#		selected_subtile_texture.texture = null
#		bitmask_label.text = ""
#	else:
#		var resize_to := min(selected_subtile_container.rect_size.x, selected_subtile_container.rect_size.y)
#		var resize_from := min(current_output_tile_size.x, current_output_tile_size.y)
#		if resize_from == 0:
#			return
#		var scale := resize_to / resize_from
#		var subtile: GeneratedSubTile = subtile_ref.get_ref()
#		var itex := ImageTexture.new()
#		if subtile.image != null:
#			itex.create_from_image(subtile.image, 0)
#		itex.set_size_override(current_output_tile_size * scale)
#		selected_subtile_texture.texture = itex
#		bitmask_label.text = str(subtile.bitmask)
#		State.emit_signal("subtile_selected", subtile.bitmask)
#	last_selected_subtile_index = subtile_index


#func _on_TextureRect_gui_input(event: InputEvent):
#	if result_texture.texture == null:
#		return
#	var tile: TPTile = State.get_current_tile()
#	if tile == null:
#		return
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

func _on_SingleTile_resized():
	select_subtile(last_selected_subtile_index)


func move_selection(delta:Vector2, frame_index: int = 0):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	var new_index := last_selected_subtile_index + delta
	if new_index in tile.frames[frame_index].parsed_template:
		select_subtile(new_index)


#
#func _unhandled_input(event: InputEvent):
#	if event is InputEventKey and event.pressed:
#		match event.scancode:
#			KEY_UP:
#				move_selection(Vector2.UP)
#				get_tree().set_input_as_handled()
#			KEY_DOWN:
#				move_selection(Vector2.DOWN)
#				get_tree().set_input_as_handled()
#			KEY_LEFT:
#				move_selection(Vector2.LEFT)
#				get_tree().set_input_as_handled()
#			KEY_RIGHT:
#				move_selection(Vector2.RIGHT)
#				get_tree().set_input_as_handled()

