class_name GodotTileRow
extends ColorRect


signal clicked()

const COLOR_WARNING := Color("#a73f00")
const COLOR_SELECT := Color.lightslategray
const MODE_NAMES := {
	TileSet.SINGLE_TILE: "Single",
	TileSet.AUTO_TILE: "Autotile",
	TileSet.ATLAS_TILE: "Atlas",
}
const BITMASK_MODE_NAMES := {
	Const.GODOT_AUTOTILE_TYPE.BLOB_3x3: "3x3min",
	Const.GODOT_AUTOTILE_TYPE.WANG_2x2: "2x2",
	Const.GODOT_AUTOTILE_TYPE.FULL_3x3: "3x3"
}

var tile_name: String
var tile_id: int
var texture_path: String
var bitmask_mode: int
var is_temp := true
var nodes_located := false
var name_rect: ColorRect
var name_label: Label
var icon: TextureRect
var mode_label: Label
var path_rect: ColorRect
var path_label: Label
var path_warning: TextureRect
var collisions_check: CheckBox


func _locate_nodes():
	if not nodes_located:
		nodes_located = true
		name_rect = $HBox/Name
		name_label = name_rect.get_node("Label")
		icon = $HBox/Icon
		mode_label = $HBox/TileMode
		path_rect = $HBox/Path
		path_label = path_rect.get_node("HBox/Label")
		path_warning = path_rect.get_node("HBox/Control2/WarningSign")
		collisions_check = $HBox/Collisions


func populate(new_tile_name: String, new_tile_id: int, new_texture_path: String, image: Image, 
		icon_rect: Rect2, tile_mode: int, new_bitmask_mode: int, has_collisions: bool, is_new: bool = false):
	_locate_nodes()
	set_tile_name(new_tile_name)
	tile_id = new_tile_id
	set_tile_mode(tile_mode, new_bitmask_mode)
	set_texture_path(new_texture_path)
	is_temp = is_new
	if image != null and image is Image:
		var icon_image := Image.new()
		icon_image.create(int(icon_rect.size.x), int(icon_rect.size.y), false, Image.FORMAT_RGBA8)
		icon_image.blit_rect(image, icon_rect, Vector2.ZERO)
		icon_image.resize(int(icon.rect_size.x), int(icon.rect_size.y))
		var icon_texture := ImageTexture.new()
		icon_texture.create_from_image(icon_image)
		icon.texture = icon_texture
	set_collisions(has_collisions)


func highlight_name(is_on: bool):
	_locate_nodes()
	if is_on:
		name_rect.color.a = 1.0
		color.a = 0.25
	else:
		name_rect.color.a = 0.0
		color.a = 0.0


func highlight_path(is_on: bool, is_warning: bool = false):
	_locate_nodes()
	if is_on:
		if is_warning:
			path_rect.color = COLOR_WARNING
			path_warning.show()
		else:
			path_rect.color = COLOR_SELECT
			path_warning.hide()
		path_rect.color.a = 1.0
	else:
		path_rect.color.a = 0.0
		path_warning.hide()


func _on_Existing_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and not is_temp:
		emit_signal("clicked", self)


func _ready():
	if is_temp:
		$TextureRect.show()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
#		$HBox.rect_min_size.y = 136
#		$HBox.margin_top = 2
		hint_tooltip = "This tile will be added to the tileset"


func set_tile_name(new_tile_name: String):
	tile_name = new_tile_name
	name_label.text = tile_name


func set_tile_mode(tile_mode: int, new_bitmask_mode: int):
	bitmask_mode = new_bitmask_mode
	if MODE_NAMES.has(tile_mode):
		mode_label.text = MODE_NAMES[tile_mode]
	if BITMASK_MODE_NAMES.has(bitmask_mode):
		mode_label.text += " " + BITMASK_MODE_NAMES[bitmask_mode]


func  set_texture_path(new_texture_path: String):
	texture_path = new_texture_path
	path_label.text = texture_path


func set_collisions(has_collisions: bool):
	if has_collisions:
		collisions_check.pressed = true
	else:
		collisions_check.pressed = false
