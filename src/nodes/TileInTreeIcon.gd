extends Control

var icon_texture: Texture = null
var output_tile_size: Vector2 = Vector2.ZERO

func _draw():
	var dest_rect := Rect2(Vector2(rect_size.x - 34, 5), Vector2(32, 32))
	var source_rect := Rect2(Vector2.ZERO, output_tile_size)
	if icon_texture == null or output_tile_size == Vector2.ZERO:
		return
	draw_texture_rect_region(icon_texture, dest_rect, source_rect, Color(0.85, 0.85, 0.9, 1.0))

