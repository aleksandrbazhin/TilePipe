extends TextureRect


signal drawn()

var contours := []
var draw_scale := 1.0


func translate_contour(contour: PoolVector2Array, offset: Vector2 = Vector2.ZERO) -> PoolVector2Array:
	var texture_size := texture.get_size()
	var scale := min(rect_size.x / texture_size.x, rect_size.y / texture_size.y)
	var translate := (rect_size - texture_size * scale) / 2.0
	var new_contour:= PoolVector2Array()
	new_contour.resize(contour.size())
	for i in range(contour.size()):
		new_contour[i] = translate + (contour[i] + offset) * scale * draw_scale
	return new_contour


func add_contour(contour: Array, offset: Vector2 = Vector2.ZERO):
	contours.append(translate_contour(contour, offset))


func _draw():
	for contour in contours:
		for point in contour:
			draw_circle(point, 2.0, Color.green)
		if not Geometry.triangulate_polygon(contour).empty():
			var colors: PoolColorArray = []
			for point in contour:
				colors.append(Color(1.0, 1.0, 1.0, 0.4))
			draw_polygon(contour, colors)
		else:
			draw_polyline(contour, Color.red, 2.0)
	emit_signal("drawn")
