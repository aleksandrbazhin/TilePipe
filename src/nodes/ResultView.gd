extends ColorRect

class_name ResultView

export var single_tile_visible := true
export var controls_visible := true

onready var single_tile := $VBoxContainer/HSplitContainer/SingleTile
onready var result_texture := $VBoxContainer/HSplitContainer/Result/TextureContainer/TextureRect


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


func set_output_texture(texture: Texture):
	result_texture.texture = texture
	if texture != null:
		var image_size: Vector2 = result_texture.texture.get_size()
		result_texture.rect_size = image_size
	
#	render_progress_overlay.hide()

func clear():
	result_texture.texture = null
