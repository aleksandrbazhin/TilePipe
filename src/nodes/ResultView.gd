extends ColorRect

class_name ResultView

export var single_tile_visible := true
export var controls_visible := true

var last_selected_subtile_position := Vector2.ZERO
var last_selected_subtile_index := Vector2.ZERO

onready var selected_subtile_container := $VBoxContainer/HSplitContainer/SingleTile
onready var selected_subtile_texture := $VBoxContainer/HSplitContainer/SingleTile/SubtileTexture
onready var result_texture: TextureRect = $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect
onready var subtile_highlight := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect/SubtileHighlight
onready var subtile_selection := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect/SubtileSelection


func render_from_tile(tile: TPTile):
	var subtiles_by_bitmasks := tile.result_subtiles_by_bitmask
	set_output_texture(null)
	if subtiles_by_bitmasks.empty():
		return
	var out_image := Image.new()
	var out_image_size: Vector2 = tile.template_size * tile.output_tile_size
	out_image_size += (tile.template_size - Vector2.ONE) * tile.subtile_offset
	out_image.create(int(out_image_size.x), int(out_image_size.y), false, Image.FORMAT_RGBA8)
	var tile_rect := Rect2(Vector2.ZERO, tile.output_tile_size)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image, 0)
	for mask in subtiles_by_bitmasks.keys():
		for tile_variant_index in range(subtiles_by_bitmasks[mask].size()):
			var subtile: GeneratedSubTile = subtiles_by_bitmasks[mask][tile_variant_index]
			var tile_position: Vector2 = subtile.position_in_template * tile.output_tile_size
			tile_position +=  subtile.position_in_template * tile.subtile_offset
			if subtile.image == null:
				continue
			out_image.blit_rect(subtile.image, tile_rect, tile_position)
			itex.set_data(out_image)
	set_output_texture(itex)
	tile.output_texture = itex
	if result_texture.texture != null:
		subtile_highlight.rect_size = tile.output_tile_size
		subtile_highlight.show()
		subtile_selection.rect_size = tile.output_tile_size
		subtile_selection.show()
		highlight_subtile(Vector2.ZERO)
#		resize_selection(tile.output_tile_size)
		if not last_selected_subtile_index in tile.parsed_template:
			last_selected_subtile_position = Vector2.ZERO
			last_selected_subtile_index = Vector2.ZERO
		select_subtile(last_selected_subtile_position, last_selected_subtile_index)


func set_output_texture(texture: Texture):
	result_texture.texture = texture
	if texture != null:
		var image_size: Vector2 = result_texture.texture.get_size()
		result_texture.rect_size = image_size


func clear():
	result_texture.texture = null


func highlight_subtile(subtile_position: Vector2):
	if subtile_highlight.rect_position != subtile_position:
		subtile_highlight.rect_position = subtile_position


func select_subtile(subtile_position: Vector2, subtile_index: Vector2):
	if subtile_selection.rect_position != subtile_position:
		subtile_selection.rect_position = subtile_position
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	if not subtile_index in tile.parsed_template:
		return
	var subtile_ref: WeakRef = tile.parsed_template[subtile_index]
	if subtile_ref == null:
		selected_subtile_texture.texture = null
	else:
		var resize_to := min(selected_subtile_container.rect_size.x, selected_subtile_container.rect_size.y)
		var resize_from := min(tile.output_tile_size.x, tile.output_tile_size.y)
		if resize_from == 0:
			return
		var scale := resize_to / resize_from
		var subtile: GeneratedSubTile = subtile_ref.get_ref()
		var itex := ImageTexture.new()
		itex.create_from_image(subtile.image, 0)
		itex.set_size_override(tile.output_tile_size * scale)
		selected_subtile_texture.texture = itex
	last_selected_subtile_index = subtile_index
	last_selected_subtile_position = subtile_position


func _on_TextureRect_gui_input(event: InputEvent):
	if result_texture.texture == null:
		return
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	if not event is InputEventMouseButton and not event is InputEventMouseMotion:
		return
	var texture_size: Vector2 = result_texture.texture.get_size() 
	if event.position.x >= texture_size.x or \
			event.position.y >= texture_size.y or \
			event.position.x < 0 or event.position.y < 0:
		return
	var subtile_index: Vector2 = (event.position / tile.output_tile_size).floor()
	var subtile_position: Vector2 = subtile_index * tile.output_tile_size
#	var out_image_size: Vector2 = tile.template_size * tile.output_tile_size
#	out_image_size += (tile.template_size - Vector2.ONE) * tile.subtile_offset
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		select_subtile(subtile_position, subtile_index)
	elif event is InputEventMouseMotion:
		highlight_subtile(subtile_position)


func _on_HSplitContainer_dragged(_offset):
	select_subtile(last_selected_subtile_position, last_selected_subtile_index)
