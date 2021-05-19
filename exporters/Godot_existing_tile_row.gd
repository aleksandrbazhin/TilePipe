extends HBoxContainer

class_name Godot_tile_row

const MODE_NAMES := {
	TileSet.SINGLE_TILE: "Single",
	TileSet.AUTO_TILE: "Autotile",
	TileSet.ATLAS_TILE: "Atlas",
}

var tile_name: String
var tile_id: int
var texture_path: String


func populate(new_tile_name: String, new_tile_id: int, new_texture_path: String, 
		icon_rect: Rect2, tile_mode: int, image = null):
	tile_name = new_tile_name
	tile_id = new_tile_id
	texture_path = new_texture_path
	$NameLabel.text = tile_name
	$LineEdit.text = texture_path
	if image != null and image is Image:
		var icon_image := Image.new()
		icon_image.create(icon_rect.size.x, icon_rect.size.y, false, Image.FORMAT_RGBA8)
		icon_image.blit_rect(image, icon_rect, Vector2.ZERO)
		icon_image.resize($Icon.rect_size.x, $Icon.rect_size.y)
		var icon_texture := ImageTexture.new()
		icon_texture.create_from_image(icon_image)
		$Icon.texture = icon_texture
	if MODE_NAMES.has(tile_mode):
		$TileMode.text = MODE_NAMES[tile_mode]
	
