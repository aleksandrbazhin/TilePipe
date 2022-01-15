extends PopupDialog

class_name CollisionGenerator

enum {DIRECTION_FORWARD, DIRECTION_BACK}
const NOT_FOUND: Vector2 = Vector2(-1.0, -1.0)
const NO_WAY := -1.0
const LINE_ANGLE_DELTA := 0.1
var CLOSE_POINT_DELTA_SQ := 4

var grid_cells := 15
var is_ui_blocked := true
var full_image: Image = null
var tile_size: Vector2
var tile_spacing: Vector2
var collision_contours: Dictionary # {template_poisiton (Vector2): contour_points(PoolVector2Array)}
var collisions_accepted_by_user := false
var has_error_contour := false

onready var viewport := $VBoxContainer/MarginContainer/Viewport
onready var contours_texture_rect := $VBoxContainer/MarginContainer/Viewport/ContourTextureRect
onready var contours_display_texture_rect := $VBoxContainer/MarginContainer/VisibleTextureRect
onready var progress_bar := $VBoxContainer/MarginContainer2/HBoxContainer/ProgressBar
onready var grid_slider := $VBoxContainer/MarginContainer3/HBoxContainer/GridSlider
onready var accept_button := $VBoxContainer/MarginContainer2/HBoxContainer/SaveButton
onready var cancel_button := $VBoxContainer/MarginContainer2/HBoxContainer/CancelButton
onready var grid_label := $VBoxContainer/MarginContainer3/HBoxContainer/GridLabel
onready var grid_value_label := $VBoxContainer/MarginContainer3/HBoxContainer/GridValueLabel
onready var status_container := $VBoxContainer/MarginContainer2/HBoxContainer/StatusContainer
onready var status_progress := status_container.get_node("StatusProgress")
onready var status_fail := status_container.get_node("StatusFail")
onready var status_ok := status_container.get_node("StatusOk")


func start(new_image: Image, new_tile_size: Vector2, new_tile_spacing: int, smoothing: bool = false):
	collisions_accepted_by_user = false
	status_fail.hide()
	status_ok.hide()
	status_progress.show()
	block_ui()
	full_image = new_image
	tile_size = new_tile_size
	setup_sliders()
	tile_spacing = Vector2(new_tile_spacing, new_tile_spacing)
	var scaled_image := Image.new()
	scaled_image = full_image.duplicate()
	var image_size := full_image.get_size()
	var image_draw_scale := min(
		contours_texture_rect.rect_size.x / image_size.x, 
		contours_texture_rect.rect_size.y / image_size.y)
	if image_draw_scale != 1.0:
		var interpolation: int = Image.INTERPOLATE_LANCZOS if smoothing else Image.INTERPOLATE_NEAREST
		scaled_image.resize(int(image_size.x * image_draw_scale), int(image_size.y * image_draw_scale), interpolation)
	contours_texture_rect.draw_scale = image_draw_scale
	var itex := ImageTexture.new()
	itex.create_from_image(scaled_image)
	contours_texture_rect.texture = itex
	contours_display_texture_rect.texture = itex
	popup_centered()
	contours_texture_rect.contours = []
	contours_texture_rect.update()
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	viewport.size = contours_texture_rect.rect_size
	yield(VisualServer, "frame_post_draw")
	compute_contours()


func compute_contours():
	has_error_contour = false
	collision_contours.clear()
	contours_texture_rect.contours = []
#	var grid_resolution := tile_image.get_size() / float(grid_cells)
	CLOSE_POINT_DELTA_SQ =  int(pow(min(tile_size.x, tile_size.y) / float(grid_cells) / 2.0, 2.0))
	progress_bar.value = 0
	var size_in_tiles: Vector2 = (full_image.get_size() - tile_size) / (tile_size + tile_spacing) + Vector2.ONE
	for x in range(size_in_tiles.x):
		for y in range(size_in_tiles.y):
			var tile_template_position := Vector2(x, y)
			var tile_position := tile_template_position * (tile_size + tile_spacing)
			var contour := compute_contour_at(Rect2(tile_position, tile_size))
			if contour.empty():
				continue
			collision_contours[tile_template_position] = contour
			contours_texture_rect.add_contour(contour, tile_position)
			if Geometry.triangulate_polygon(contour).empty():
				has_error_contour = true
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	contours_texture_rect.update()
	contours_texture_rect.connect("drawn", self, "on_contours_drawn")
	progress_bar.value = 100


func setup_sliders():
	var max_grid := int(min(tile_size.x, tile_size.y))
	grid_cells = int(max_grid / 4.0)
	grid_slider.min_value = 2.0
	grid_slider.max_value = max_grid / 2.0
	grid_slider.quantize(max_grid / 2.0 - 2.0)
	grid_slider.value = grid_cells


func find_horizontal_edge_pixel(y_coord: float, tile_image: Image, direction: int) -> Vector2:
	var result := NOT_FOUND
#	var y: float = min(y_coord, tile_size.y - 1)
	var y := y_coord
	if y > tile_size.y / 2.0:
		y -= 1
	tile_image.lock()
	var prev_pixel_a := 0.0
#		var length = tile_image.get_size().x - 1
	for x in range(tile_size.x):
		var test_point := Vector2(x, y)
		if direction == DIRECTION_BACK:
			test_point.x = tile_size.x - 1 - x
		var pixel_a := tile_image.get_pixelv(test_point).a
		if prev_pixel_a == 0.0 and pixel_a != 0.0:
			if direction == DIRECTION_BACK:
				test_point.x += 1
			if test_point.y > tile_size.y / 2:
				test_point.y += 1
			tile_image.unlock()
			test_point.x = clamp(test_point.x, 0, tile_size.x)
			test_point.y = clamp(test_point.y, 0, tile_size.y)
			return test_point
		else:
			prev_pixel_a = pixel_a
	tile_image.unlock()
	return result


func find_vertical_edge_pixel(x_coord: float, tile_image: Image, direction: int) -> Vector2:
	var result := NOT_FOUND
	var x := x_coord
	if x > tile_size.x / 2.0:
		x -= 1
	tile_image.lock()
	var prev_pixel_a := 0.0
	for y in range(tile_size.y):
		var test_point := Vector2(x, y)
		if direction == DIRECTION_BACK:
			test_point.y = tile_size.y - y - 1
		var pixel_a := tile_image.get_pixelv(test_point).a
		if prev_pixel_a == 0.0 and pixel_a != 0.0:
			if direction == DIRECTION_BACK:
				test_point.y += 1
			if test_point.x > tile_size.x / 2.0:
				test_point.x += 1
			tile_image.unlock()
			test_point.x = clamp(test_point.x, 0, tile_size.x)
			test_point.y = clamp(test_point.y, 0, tile_size.y)
			return test_point 
		else:
			prev_pixel_a = pixel_a
	tile_image.unlock()
	return result


func join_mirrored_arrays(a1: PoolVector2Array, a2: PoolVector2Array) -> PoolVector2Array:
	if a1.empty() or a2.empty():
		return PoolVector2Array([])
	var center := a1.size() - 1
	a2.invert()
	a1.append_array(a2)
	a1[center + 1] = a1[center]
	a1[center] = a2[0]
	return a1


func compute_contour_at(tile_rect: Rect2) -> PoolVector2Array:
	var tile_image := Image.new()
	tile_image.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
	tile_image.blit_rect(full_image, tile_rect, Vector2.ZERO)
	var contour: PoolVector2Array = []
	var grid_resolution := tile_size / float(grid_cells)
	if not tile_image.is_invisible():
		var top: PoolVector2Array = []
		var bottom: PoolVector2Array = []
		var left: PoolVector2Array = []
		var right: PoolVector2Array = []
		for i in range((grid_cells + 1)):
			var x_test_coord := i * grid_resolution.x
			var point := Vector2.ZERO
			point = find_vertical_edge_pixel(x_test_coord, tile_image, DIRECTION_FORWARD)
			if point != NOT_FOUND:
				top.append(point)
			point = find_vertical_edge_pixel(x_test_coord, tile_image, DIRECTION_BACK)
			if point != NOT_FOUND:
				bottom.append(point)
			var y_test_coord := i * grid_resolution.y
			point = find_horizontal_edge_pixel(y_test_coord, tile_image, DIRECTION_BACK)
			if point != NOT_FOUND:
				right.append(point)
			point = find_horizontal_edge_pixel(y_test_coord, tile_image, DIRECTION_FORWARD)
			if point != NOT_FOUND:
				left.append(point)

#		var top1: PoolVector2Array = []
#		var bottom1: PoolVector2Array  = []
#		var left1: PoolVector2Array = []
#		var right1: PoolVector2Array = []
#		var top2: PoolVector2Array = []
#		var bottom2: PoolVector2Array  = []
#		var left2: PoolVector2Array = []
#		var right2: PoolVector2Array = []
#		for i in range((grid_cells / 2 + 1)):
#			var x_test_coord := i * grid_resolution.x
#			var point := Vector2.ZERO
#			point = find_vertical_edge_pixel(x_test_coord, tile_image, DIRECTION_FORWARD)
#			if point != NOT_FOUND:
#				top1.append(point)
#			point = find_vertical_edge_pixel(tile_size.x - x_test_coord - 1, tile_image, DIRECTION_FORWARD)
#			if point != NOT_FOUND:
#				top2.append(point)
#			point = find_vertical_edge_pixel(x_test_coord, tile_image, DIRECTION_BACK)
#			if point != NOT_FOUND:
#				bottom1.append(point)
#			point = find_vertical_edge_pixel(tile_size.x - x_test_coord - 1, tile_image, DIRECTION_BACK)
#			if point != NOT_FOUND:
#				bottom2.append(point)
#			var y_test_coord := i * grid_resolution.y
#			point = find_horizontal_edge_pixel(y_test_coord, tile_image, DIRECTION_BACK)
#			if point != NOT_FOUND:
#				right1.append(point)
#			point = find_horizontal_edge_pixel(tile_size.y - y_test_coord - 1, tile_image, DIRECTION_BACK)
#			if point != NOT_FOUND:
#				right2.append(point)
#			point = find_horizontal_edge_pixel(y_test_coord, tile_image, DIRECTION_FORWARD)
#			if point != NOT_FOUND:
#				left1.append(point)
#			point = find_horizontal_edge_pixel(tile_size.y - y_test_coord - 1, tile_image, DIRECTION_FORWARD)
#			if point != NOT_FOUND:
#				left2.append(point)
##		var top: PoolVector2Array = join_mirrored_arrays(top1, top2)
##		var bottom: PoolVector2Array = join_mirrored_arrays(bottom1, bottom2)
##		var left: PoolVector2Array = join_mirrored_arrays(left1, left2)
##		var right: PoolVector2Array = join_mirrored_arrays(right1, right2)

		if left.empty() and right.empty() and top.empty() and bottom.empty():
			print("Can not detect contour in position ", tile_rect.position)
			return contour
		# cutoff overlapping left and right
		contour = merge_side_lines(top, bottom, left, right)
		contour = simplify_contour(contour)
#		contour = improve_contour(contour, max(grid_resolution.x, grid_resolution.y), tile_image)
	return contour


func remove_side_overlap(side: PoolVector2Array, top_cutoff: Vector2, bottom_cutoff: Vector2) -> PoolVector2Array:
	var result: PoolVector2Array = []
	for point in side:
		if point.y > top_cutoff.y and point.y < bottom_cutoff.y:
			result.append(point)
	result = remove_close_side_end_points(result, top_cutoff, bottom_cutoff)
	return result


func merge_side_lines(top: PoolVector2Array, bottom: PoolVector2Array, left: PoolVector2Array, right: PoolVector2Array) -> PoolVector2Array:
	var contour_result: PoolVector2Array = []
#	var left_start := get_side_overlap(left, top[0], DIRECTION_FORWARD)
#	var left_end := get_side_overlap(left, bottom[0], DIRECTION_BACK)
#	var fixed_left := PoolVector2Array(Array(left).slice(left_start, left_end))
	var fixed_left := remove_side_overlap(left, top[0], bottom[0])
#	print("left: ", left, " - ", fixed_left)
#	var right_start := get_side_overlap(right, top[-1], DIRECTION_FORWARD)
#	var right_end := get_side_overlap(right, bottom[-1], DIRECTION_BACK)
#	var fixed_right := PoolVector2Array(Array(right).slice(right_start, right_end))
	
	var fixed_right := remove_side_overlap(right, top[-1], bottom[-1])
#	print("right: ", right, " - ", fixed_right)
	#fixed_right = remove_close_side_end_points(fixed_right, top[-1], bottom[-1])
	contour_result.append_array(top)
	contour_result.append_array(fixed_right)
	bottom.invert()
	contour_result.append_array(bottom)
	fixed_left.invert()
	contour_result.append_array(fixed_left)
	return contour_result


func remove_close_side_end_points(side: PoolVector2Array, top_point: Vector2, bottom_point: Vector2) -> PoolVector2Array:
#	print(top_point, bottom_point)
	if side.empty():
		return side
	if side[0].distance_squared_to(top_point) < CLOSE_POINT_DELTA_SQ:
		side.remove(0)
	if side.empty():
		return side
	if side[-1].distance_squared_to(bottom_point) < CLOSE_POINT_DELTA_SQ:
		side.remove(side.size() - 1)
	return side


func on_contours_drawn():
	status_progress.hide()
	if has_error_contour:
		status_ok.hide()
		status_fail.show()
	else:
		status_fail.hide()
		status_ok.show()
	contours_texture_rect.disconnect("drawn", self, "on_contours_drawn")
	yield(VisualServer, "frame_post_draw")
	viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	var itex := ImageTexture.new()
	itex.create_from_image(viewport.get_texture().get_data())
	contours_display_texture_rect.texture = itex
	unblock_ui()
	if has_error_contour:
		accept_button.disabled = true
	else:
		accept_button.disabled = false


func get_side_overlap(side_points: Array, cutoff: Vector2, vertical_direction: int) -> int:
#	print("cutoff: ", cutoff.y)
	var range_from := 0 if vertical_direction == DIRECTION_FORWARD else side_points.size() - 1
	var increment: int = 1 if vertical_direction == DIRECTION_FORWARD else -1
	var range_to: int = side_points.size() - 1 - range_from
	var overlap_index := range_from
	for i in range(range_from, range_to, increment):
		var is_y_overlapping: bool = side_points[i].y >= cutoff.y if \
			vertical_direction == DIRECTION_FORWARD else side_points[i].y <= cutoff.y
		print(i, " ", side_points[i].y, " ", is_y_overlapping)
		overlap_index = i
		if is_y_overlapping:
			overlap_index = i
			break
		else:
			overlap_index = i + increment
	return overlap_index


# removes points on the straight line between neigbors
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


## elongate straight lines
#func improve_contour(contour: PoolVector2Array, grid_resolution_px: float, tile_image: Image) -> PoolVector2Array:
#	tile_image.lock()
##	print(contour)
#	for i in range(contour.size()):
#		var next_i: int = i + 1 if i < contour.size() - 1 else 0
#		var section_vec := (contour[next_i] - contour[i]).normalized()
#		var new_point := contour[i]
#		for step in grid_resolution_px:
#			var test_point: Vector2 = contour[i] - section_vec * step 
#			test_point = test_point.snapped(Vector2.ONE)
#			if test_point.x >= tile_size.x or test_point.y >= tile_size.y or test_point.x < 0 or test_point.y < 0:
#				break
#			if tile_image.get_pixelv(test_point).a == 0.0:
#				break
#			new_point = test_point
#		contour[i] = new_point
#		var new_next := contour[next_i]
#		for step in grid_resolution_px:
#			var test_point: Vector2 = contour[next_i] + section_vec * step 
#			test_point = test_point.snapped(Vector2.ONE)
#			if test_point.x >= tile_size.x or test_point.y >= tile_size.y or test_point.x < 0 or test_point.y < 0:
#				break
#			if tile_image.get_pixelv(test_point).a == 0.0:
#				break
#			new_next = test_point
#		contour[next_i] = new_next
#	tile_image.unlock()
#	var point_neighbor_checks := []
#	for i in range(contour.size()):
#		var point: Vector2 = contour[i]
#		var next_point: Vector2 = contour[i + 1] if i < contour.size() - 1 else contour[0]
#		if point.distance_squared_to(next_point) < CLOSE_POINT_DELTA_SQ:
#			point_neighbor_checks.append(true)
#		else:
#			point_neighbor_checks.append(false)
#	var result_contour: PoolVector2Array = []
#	for i in range(contour.size()):
#		var point_index := i
#		var next_point_index := i + 1 if i < contour.size() - 1 else 0
#		if not(point_neighbor_checks[point_index] and not point_neighbor_checks[next_point_index]):
#			result_contour.append(contour[point_index])
#	return result_contour


func _on_CloseButton_pressed():
	collisions_accepted_by_user = false
	hide()


func _on_SaveButton_pressed():
	if not has_error_contour:
		collisions_accepted_by_user = true
		hide()


func _on_GridSlider_released(value):
	grid_cells = value
	progress_bar.value = 0
	block_ui()
	yield(VisualServer, "frame_post_draw")
	compute_contours()


func block_ui():
	is_ui_blocked = true
	grid_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accept_button.disabled = true
	cancel_button.disabled = true
	grid_label.add_color_override("font_color", Color.darkgray)
	grid_value_label.add_color_override("font_color", Color.darkgray)


func unblock_ui():
	is_ui_blocked = false
	grid_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	accept_button.disabled = false
	cancel_button.disabled = false
	grid_label.add_color_override("font_color", Color.white)
	grid_value_label.add_color_override("font_color", Color.white)


func _on_GridSlider_value_changed(value):
	grid_value_label.text = str(value)
