extends TextureRect

enum {DIRECTION_FORWARD, DIRECTION_BACK}
const NOT_FOUND: Vector2 = Vector2(-1.0, -1.0)
const NO_WAY := -1.0
const SEARCH_STEP := 1.0
const GRID_CELLS := 15
const DISTANCE_DELTA_SQ := 16
const LINE_ANGLE_DELTA := 0.1


func find_edge_pixel(ray: Vector2, direction = DIRECTION_FORWARD) -> Vector2:
	var result := NOT_FOUND
	if ray.y == NO_WAY:
		ray.x = min(ray.x, texture.get_size().x - 1)
		var image: Image = texture.get_data()
		image.lock()
		var prev_pixel_a := 0.0
		var length = texture.get_size().y - 1
		for y in range(0, length, SEARCH_STEP):
			var test_point := Vector2(ray.x, y)
			if direction == DIRECTION_BACK:
				test_point.y = length - y
			var pixel_a := image.get_pixelv(test_point).a
			if prev_pixel_a == 0.0 and pixel_a != 0.0:
				return test_point
			else:
				prev_pixel_a = pixel_a
			pass
		image.unlock()

	elif ray.x == NO_WAY:
		ray.y = min(ray.y, texture.get_size().y - 1)
		var image: Image = texture.get_data()
		image.lock()
		var prev_pixel_a := 0.0
		var length = texture.get_size().y - 1
		for x in range(0, length, SEARCH_STEP):
			var test_point := Vector2(x, ray.y)
			if direction == DIRECTION_BACK:
				test_point.x = length - x
			var pixel_a := image.get_pixelv(test_point).a
			if prev_pixel_a == 0.0 and pixel_a != 0.0:
				return test_point
			else:
				prev_pixel_a = pixel_a
			pass
		image.unlock()

	else:
		print("ERROR: NOT AXIS ALIGNED RAY")
	return result


func _draw():
	draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), Color.darkgray)
	draw_texture(texture, Vector2.ZERO)
	var top: PoolVector2Array = []
	var bottom: PoolVector2Array  = []
	var left := []
	var right := []
	for line in range(GRID_CELLS + 1):
		var ray := Vector2(line * texture.get_size().x / float(GRID_CELLS), NO_WAY)
		var point := find_edge_pixel(ray, DIRECTION_BACK)
		if point != NOT_FOUND:
			bottom.append(point)
		point = find_edge_pixel(ray)
		if point != NOT_FOUND:
			top.append(point)
		ray = Vector2(NO_WAY, line * texture.get_size().y / float(GRID_CELLS))
		point = find_edge_pixel(ray, DIRECTION_BACK)
		if point != NOT_FOUND:
			right.append(point)
		point = find_edge_pixel(ray)
		if point != NOT_FOUND:
			left.append(point)
	# cutoff overlapping left and right
	var left_start := get_side_overlap(left, top[0], DIRECTION_FORWARD)
	var left_end := get_side_overlap(left, bottom[0], DIRECTION_BACK)
	var right_start := get_side_overlap(right, top[-1], DIRECTION_FORWARD)
	var right_end := get_side_overlap(right, bottom[-1], DIRECTION_BACK)
	var fixed_left := PoolVector2Array(left.slice(left_start, left_end))
	var fixed_right := PoolVector2Array(right.slice(right_start, right_end))
	var contour: PoolVector2Array = []
	
	contour.append_array(top)
	contour.append_array(fixed_right)
	bottom.invert()
	contour.append_array(bottom)
	fixed_left.invert()
	contour.append_array(fixed_left)
	for point in contour:
		draw_circle(point, 3.0, Color.red)
	contour = remove_close_points(contour)
	contour = simplify_contour(contour)
	for point in contour:
		draw_circle(point, 2.0, Color.green)

	if not Geometry.triangulate_polygon(contour).empty():
		var colors: PoolColorArray = []
		for point in contour:
			colors.append(Color(1.0, 1.0, 1.0, 0.66))
		draw_polygon(contour, colors)
	else:
		print("ERROR")
		print(contour)
		draw_polyline(contour, Color.white)
		draw_polyline(right, Color.red, 2.0)
		draw_polyline(fixed_right, Color.green, 1.0)
		draw_polyline(left, Color.red, 2.0)
		draw_polyline(fixed_left, Color.green, 1.0)


func get_side_overlap(side_points: Array, cutoff: Vector2, vertical_direction: int) -> int:
	var overlap_index := 0 if vertical_direction == DIRECTION_FORWARD else side_points.size() - 1
	var increment: int = 1 if vertical_direction == DIRECTION_FORWARD else -1
	for i in range(overlap_index, side_points.size() - 1 - overlap_index, increment):
		var is_y_overlapping: bool = side_points[i].y >= cutoff.y if \
			vertical_direction == DIRECTION_FORWARD else side_points[i].y <= cutoff.y
		if is_y_overlapping:
			overlap_index = i
			break
		else:
			overlap_index = i + increment
	return overlap_index

# TODO: improve
func simplify_contour(contour: PoolVector2Array) -> PoolVector2Array:
	var point_checks := []
	for i in range(contour.size()):
		var prev_point: Vector2 = contour[i - 1] if i > 0 else contour[-1]
		var point: Vector2 = contour[i]
		var next_point: Vector2 = contour[i + 1] if i < contour.size() - 1 else contour[0]
		var segment1 := point - prev_point
		var segment2 := next_point - point
		if abs(segment1.angle_to(segment2)) < LINE_ANGLE_DELTA:
			point_checks.append(false)
		else:
			point_checks.append(true)
	var result_contour: PoolVector2Array = []
	for i in range(point_checks.size()):
		if point_checks[i]:
			result_contour.append(contour[i])
	return result_contour

#TODO: caheck only sie ends?
func remove_close_points(contour: PoolVector2Array) -> PoolVector2Array:
	var point_neighbor_checks := []
	for i in range(contour.size()):
		var point: Vector2 = contour[i]
		var next_point: Vector2 = contour[i + 1] if i < contour.size() - 1 else contour[0]
		if point.distance_squared_to(next_point) < DISTANCE_DELTA_SQ:
			point_neighbor_checks.append(true)
		else:
			point_neighbor_checks.append(false)
	var result_contour: PoolVector2Array = []
	for i in range(contour.size()):
		var point_index := i
		var next_point_index := i + 1 if i < contour.size() - 1 else 0
		if not(point_neighbor_checks[point_index] and not point_neighbor_checks[next_point_index]):
			result_contour.append(contour[point_index])
	return result_contour
