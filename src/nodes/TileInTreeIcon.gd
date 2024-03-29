class_name TileInTreeIcon
extends Control

var icon_texture: Texture = null
var output_tile_size: Vector2 = Vector2.ZERO


func _draw():
	var dest_rect := Rect2(Vector2(rect_size.x - 33, 4), Vector2(32, 32))
	if icon_texture == null or output_tile_size == Vector2.ZERO:
		draw_rect(dest_rect, Color.transparent)
		return
	draw_texture_rect(icon_texture, dest_rect, false, Color(0.88, 0.88, 0.92, 1.0))
