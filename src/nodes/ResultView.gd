extends ColorRect

class_name ResultView

export var single_tile_visible := true
export var controls_visible := true

onready var single_tile := $VBoxContainer/HSplitContainer/SingleTile
onready var result_texture := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect
#onready var controls := $VBoxContainer/HSplitContainer/Result/ImageSettings

#
#func _ready():
#	if not single_tile_visible:
#		single_tile.hide()
#	if not controls_visible:
#		controls.hide()


func render_from_tile(tile: TileInTree):
#	if tile.result_subtiles_by_bitmask.empty():
#		return
	var tiles_by_bitmasks := tile.result_subtiles_by_bitmask
	set_output_texture(null)
	if tiles_by_bitmasks.empty():
		return
#	var tile_size: int = tile.output_tile_size
#	rotated_texture_in_viewport.show()
#	if rotate_viewport.size != new_viewport_size:
#		rotate_viewport.size = new_viewport_size
#		rotated_texture_in_viewport.rect_size = new_viewport_size
	var out_image := Image.new()
#	var template_size:= Vector2(12, 6)
	var out_image_size: Vector2 = tile.template_size * tile.output_tile_size
#	out_image_size += (template_size - Vector2.ONE) * output_tile_offset
	out_image.create(int(out_image_size.x), int(out_image_size.y), false, Image.FORMAT_RGBA8)
	var tile_rect := Rect2(Vector2.ZERO, tile.output_tile_size)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image, 0)
	for mask in tiles_by_bitmasks.keys():
		for tile_variant_index in range(tiles_by_bitmasks[mask].size()):
			var subtile: GeneratedSubTile = tiles_by_bitmasks[mask][tile_variant_index]
#			var tile_position: Vector2 = generated_tile.position_in_template * (tile_size + output_tile_offset)
#			print(mask, subtile.position_in_template)
			var tile_position: Vector2 = subtile.position_in_template * tile.output_tile_size
			if subtile.image == null:
#				print("null")
				continue
			out_image.blit_rect(subtile.image, tile_rect, tile_position)
			itex.set_data(out_image)
	set_output_texture(itex)
#	rotated_texture_in_viewport.hide()


func set_output_texture(texture: Texture):
	result_texture.texture = texture
	if texture != null:
		var image_size: Vector2 = result_texture.texture.get_size()
		result_texture.rect_size = image_size
#		output_control.rect_min_size = image_size
#	else:
#		output_control.rect_min_size = Vector2.ZERO
#	render_progress_overlay.hide()


