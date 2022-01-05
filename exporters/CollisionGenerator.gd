extends PopupDialog

class_name CollisionGenerator

enum {DIRECTION_FORWARD, DIRECTION_BACK}
const NOT_FOUND: Vector2 = Vector2(-1.0, -1.0)
const NO_WAY := -1.0
const SEARCH_STEP := 1.0
const GRID_CELLS := 15 # TODO: сделать пропорциональным размеру тайла
const DISTANCE_DELTA_SQ := 9 # TODO: сделать пропорциональным размеру тайла
const LINE_ANGLE_DELTA := 0.1

var full_image: Image = null
var tile_size: Vector2
var tile_spacing: Vector2
var collision_contours: Dictionary
var collisions_accepted := false

onready var viewport := $VBoxContainer/MarginContainer/Viewport
onready var contours_texture_rect := $VBoxContainer/MarginContainer/Viewport/ContourTextureRect
onready var contours_display_texture_rect := $VBoxContainer/MarginContainer/VisibleTextureRect
onready var progress_bar := $VBoxContainer/MarginContainer2/HBoxContainer/ProgressBar


func start(new_image: Image, new_tile_size: Vector2, new_tile_spacing: int):
	full_image = new_image
	tile_size = new_tile_size
	tile_spacing = Vector2(new_tile_spacing, new_tile_spacing)
	var itex := ImageTexture.new()
	itex.create_from_image(full_image)
	contours_texture_rect.texture = itex
	contours_display_texture_rect.texture = itex
	popup_centered()
	contours_texture_rect.contours = []
	contours_texture_rect.update()
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	viewport.size = contours_texture_rect.rect_size
	yield(VisualServer, "frame_post_draw")
	compute_contours()


func _on_CloseButton_pressed():
	collisions_accepted = false
	hide()


func _on_SaveButton_pressed():
	collisions_accepted = true
	hide()


func compute_contour_at(tile_rect: Rect2) -> PoolVector2Array:
	var tile_image := Image.new()
	tile_image.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
	tile_image.blit_rect(full_image, tile_rect, Vector2.ZERO)
	var contour: PoolVector2Array = []
	if not tile_image.is_invisible():
		var top: PoolVector2Array = []
		var bottom: PoolVector2Array  = []
		var left := []
		var right := []
		for line in range(GRID_CELLS + 1):
			var ray := Vector2(line * tile_image.get_size().x / float(GRID_CELLS), NO_WAY)
			var point := find_edge_pixel(ray, tile_image, DIRECTION_BACK)
			if point != NOT_FOUND:
				bottom.append(point)
			point = find_edge_pixel(ray, tile_image, DIRECTION_FORWARD)
			if point != NOT_FOUND:
				top.append(point)
			ray = Vector2(NO_WAY, line * tile_image.get_size().y / float(GRID_CELLS))
			point = find_edge_pixel(ray, tile_image, DIRECTION_BACK)
			if point != NOT_FOUND:
				right.append(point)
			point = find_edge_pixel(ray, tile_image, DIRECTION_FORWARD)
			if point != NOT_FOUND:
				left.append(point)
		if left.empty() and right.empty() and top.empty() and bottom.empty():
			print("Can not detect contour in position ", tile_rect.position)
			return contour
		# cutoff overlapping left and right
		var left_start := get_side_overlap(left, top[0], DIRECTION_FORWARD)
		var left_end := get_side_overlap(left, bottom[0], DIRECTION_BACK)
		var right_start := get_side_overlap(right, top[-1], DIRECTION_FORWARD)
		var right_end := get_side_overlap(right, bottom[-1], DIRECTION_BACK)
		var fixed_left := PoolVector2Array(left.slice(left_start, left_end))
		var fixed_right := PoolVector2Array(right.slice(right_start, right_end))
		contour.append_array(top)
		contour.append_array(fixed_right)
		bottom.invert()
		contour.append_array(bottom)
		fixed_left.invert()
		contour.append_array(fixed_left)
		contour = remove_close_points(contour)
		contour = simplify_contour(contour)
	return contour


func compute_contours():
	contours_texture_rect.contours = []
	progress_bar.value = 0
	var size_in_tiles: Vector2 = (full_image.get_size() - tile_size) / (tile_size + tile_spacing) + Vector2.ONE
#	var tile_size: Vector2 = image.get_size() / size_in_tiles
	for x in range(size_in_tiles.x):
		for y in range(size_in_tiles.y):
			var tile_template_position := Vector2(x, y)
			var tile_position := tile_template_position * (tile_size + tile_spacing)
			var contour := compute_contour_at(Rect2(tile_position, tile_size))
			if not contour.empty():
				for i in range(contour.size()):
					contour[i] = contour[i] + tile_position
				collision_contours[tile_template_position] = contour
				contours_texture_rect.add_contour(contour)
#		progress_bar.value = int(x / size_in_tiles.x * 100.0)
#		yield(VisualServer, "frame_post_draw")
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	contours_texture_rect.update()
	contours_texture_rect.connect("drawn", self, "constours_drawn")
	progress_bar.value = 100


func constours_drawn():
	contours_texture_rect.disconnect("drawn", self, "constours_drawn")
	yield(VisualServer, "frame_post_draw")
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	var itex := ImageTexture.new()
	itex.create_from_image(viewport.get_texture().get_data())
	contours_display_texture_rect.texture = itex


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


func find_edge_pixel(ray: Vector2, tile_image: Image, direction: int) -> Vector2:
	var result := NOT_FOUND
	if ray.y == NO_WAY:
		ray.x = min(ray.x, tile_image.get_size().x - 1)
#		var image: Image = texture.get_data()
		tile_image.lock()
		var prev_pixel_a := 0.0
		var length = tile_image.get_size().y - 1
		for y in range(0, length, SEARCH_STEP):
			var test_point := Vector2(ray.x, y)
			if direction == DIRECTION_BACK:
				test_point.y = length - y
			var pixel_a := tile_image.get_pixelv(test_point).a
			if prev_pixel_a == 0.0 and pixel_a != 0.0:
				return test_point
			else:
				prev_pixel_a = pixel_a
			pass
		tile_image.unlock()

	elif ray.x == NO_WAY:
		ray.y = min(ray.y, tile_image.get_size().y - 1)
#		var image: Image = texture.get_data()
		tile_image.lock()
		var prev_pixel_a := 0.0
		var length = tile_image.get_size().y - 1
		for x in range(0, length, SEARCH_STEP):
			var test_point := Vector2(x, ray.y)
			if direction == DIRECTION_BACK:
				test_point.x = length - x
			var pixel_a := tile_image.get_pixelv(test_point).a
			if prev_pixel_a == 0.0 and pixel_a != 0.0:
				return test_point
			else:
				prev_pixel_a = pixel_a
			pass
		tile_image.unlock()

	else:
		print("ERROR: NOT AXIS ALIGNED RAY")
	return result

