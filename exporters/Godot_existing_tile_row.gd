extends ColorRect

class_name Godot_tile_row

signal clicked()

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
	$HBox/Name/Label.text = tile_name
	$HBox/Path/Label.text = texture_path
	if image != null and image is Image:
		var icon_image := Image.new()
		icon_image.create(icon_rect.size.x, icon_rect.size.y, false, Image.FORMAT_RGBA8)
		icon_image.blit_rect(image, icon_rect, Vector2.ZERO)
		icon_image.resize($HBox/Icon.rect_size.x, $HBox/Icon.rect_size.y)
		var icon_texture := ImageTexture.new()
		icon_texture.create_from_image(icon_image)
		$HBox/Icon.texture = icon_texture
	if MODE_NAMES.has(tile_mode):
		$HBox/TileMode.text = MODE_NAMES[tile_mode]
	
func highlight_name(is_on: bool):
	if is_on:
		$HBox/Name.color.a = 1.0
		color.a = 0.25
	else:
		$HBox/Name.color.a = 0.0
		color.a = 0.0

func highlight_path(is_on: bool):
	if is_on:
		$HBox/Path.color.a = 1.0
	else:
		$HBox/Path.color.a = 0.0

func _on_Existing_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("clicked", self)
