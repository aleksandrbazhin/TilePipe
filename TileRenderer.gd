extends Node

class_name TileRenderer

signal tiles_ready()
signal report_progress(progress)

const RENDER_POOL_SIZE = 16


var is_rendering = false
var render_pool := []

var render_progress := 0 # from 0 to 100
var input_tile_parts := {}
var template
var ruleset: GenerationData
var input_tile_size := Vector2.ZERO
var output_tile_size := Vector2.ZERO
var rng: RandomNumberGenerator
var smoothing_enabled := false
var ready = false
var last_mask := 0
# tiles[mask] = [random_variant1, random_variant2, ...]
var tiles := {} 


func _ready():
	VisualServer.connect("frame_post_draw", self, "on_render")
	init_render_pool()
	ready = true


func init_render_pool():
	for _i in range(RENDER_POOL_SIZE):
		var viewport := Viewport.new()
		render_pool.append(viewport)
		viewport.transparent_bg = true
		viewport.disable_3d = true
		viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
		viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		viewport.render_target_v_flip = true
		viewport.size_override_stretch = true
		var texture_rect := TextureRect.new()
		var material: ShaderMaterial = preload("res://tile_shader_material.tres")
		texture_rect.material = material.duplicate()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		viewport.add_child(texture_rect, true)
		add_child(viewport)


func start_render(new_ruleset: GenerationData, new_input_tile_size: Vector2, new_output_tile_size: Vector2,
		input_image: Image, template_bitmasks: Dictionary, new_smoothing_enabled: bool,
		merge_rate: float, overlap_rate: float, active_rng: RandomNumberGenerator):
	tiles = template_bitmasks
	ruleset = new_ruleset
	input_tile_size = new_input_tile_size
	output_tile_size = new_output_tile_size
	input_tile_parts = split_input_into_tile_parts(input_image)
	smoothing_enabled = new_smoothing_enabled
	rng = active_rng
	last_mask = tiles.keys()[0]
	for viewport in render_pool:
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.size = input_tile_size
		var texture_node = viewport.get_node("TextureRect")
		texture_node.rect_size = input_tile_size
		texture_node.material.set_shader_param("overlay_rate", merge_rate)
		texture_node.material.set_shader_param("overlap", overlap_rate)
	render_next_batch()
	is_rendering = true


func split_input_into_tile_parts(input_image: Image) -> Dictionary:
	var parts := {}
	var min_input_tiles := ruleset.get_min_input_size()
	for part_index in range(min_input_tiles.x):
		parts[part_index] = []
		var part_is_empty := false
		var variant_index := 0
		while not part_is_empty:
			var part := Image.new()
			part.create(int(input_tile_size.x), int(input_tile_size.y), false, Image.FORMAT_RGBA8)
			if input_tile_size.y + variant_index * input_tile_size.y > input_image.get_size().y:
				break
			var copy_rect := Rect2(part_index * input_tile_size.x, variant_index * input_tile_size.y, 
				input_tile_size.x, input_tile_size.y)
			part.blit_rect(input_image, copy_rect, Vector2.ZERO)
			if part.is_invisible():
				part_is_empty = true
			else:
				parts[part_index].append(part)
				variant_index += 1
	return parts


func setup_tile_render(mask: int, viewport: Viewport):
	var overlap_vectors: Array = ruleset.get_overlap_vectors()
	var overlap_vector_rotations: Array = ruleset.get_overlap_vector_rotations()
	var random_center_index: int = 0
	var center_image: Image = input_tile_parts[0][random_center_index]
	var tile_rules_data: Dictionary = ruleset.get_mask_data(mask)
	var parts_rules: Array = tile_rules_data["generate_piece_indexes"]
	var parts_rotations: Array = tile_rules_data["generate_piece_rotations"]
	assert (parts_rules.size() == 8 && parts_rotations.size() == 8)
	var itex = ImageTexture.new()
	itex.create_from_image(center_image, 0)
	var texture_rect: TextureRect = viewport.get_node("TextureRect")
	texture_rect.texture = itex
	var piece_set := [-1, -1, -1, -1, -1, -1, -1, -1]
	var piece_random := [0, 0, 0, 0, 0, 0, 0, 0]
	var mask_index: int = 0
	for mask_name in Const.TILE_MASK:
		var piece_index: int = parts_rules[mask_index]
		var random_tile_index: int = 0
		var existing_piece_index := piece_set.find(piece_index)
		if existing_piece_index != -1:
			random_tile_index = piece_random[existing_piece_index]
		else:
			random_tile_index = rng.randi_range(0, input_tile_parts[piece_index].size() - 1)
			piece_random[mask_index] = random_tile_index
		piece_set[mask_index] = piece_index
		var piece_rot_index: int = parts_rotations[mask_index]
		var rotation_shift: int = Const.ROTATION_SHIFTS.keys()[piece_rot_index]
		var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_shift]["angle"]
		var overlay_image := Image.new()
		overlay_image.copy_from(input_tile_parts[piece_index][random_tile_index])
		if bool(tile_rules_data["generate_piece_flip_x"][mask_index]):
			overlay_image.flip_x()
		if bool(tile_rules_data["generate_piece_flip_y"][mask_index]):
			overlay_image.flip_y()
		var piece_itex = ImageTexture.new()
		piece_itex.create_from_image(overlay_image, 0)
		var mask_key: int = Const.TILE_MASK[mask_name]
		texture_rect.material.set_shader_param("overlay_texture_%s" % mask_key, piece_itex)
		texture_rect.material.set_shader_param("rotation_%s" % mask_key, -rotation_angle)
		var overlap_vec: Vector2 = overlap_vectors[piece_index]
		if overlap_vector_rotations[piece_index] and (rotation_angle == PI / 2 or rotation_angle == 3 * PI / 2):
			overlap_vec.x = 0.0 if overlap_vec.x == 1.0 else 1.0
			overlap_vec.y = 0.0 if overlap_vec.y == 1.0 else 1.0
		texture_rect.material.set_shader_param("ovelap_direction_%s" % mask_key, overlap_vec)
		mask_index += 1


func render_next_batch():
	for viewport in render_pool:
		var tile: GeneratedTile = get_next_tile()
		if tile != null:
			last_mask = tile.mask
			tile.is_rendering = true
			setup_tile_render(tile.mask, viewport)
			viewport.set_meta("tile", tile)
		else:
			viewport.remove_meta("tile")


func get_next_tile() -> GeneratedTile:
	for tile in tiles[last_mask]:
		if tile.image == null and not tile.is_rendering:
			return tile
	var mask_index := tiles.keys().find(last_mask)
	if mask_index == tiles.size() - 1:
		return null
	var next_mask = tiles.keys()[mask_index + 1]
	return tiles[next_mask][0]


func capture_rendered_batch():
	for viewport in render_pool:
		if viewport.has_meta("tile"):
			var tile: GeneratedTile = viewport.get_meta("tile")
			var tile_texture: ViewportTexture = viewport.get_texture()
			tile.capture_texture(tile_texture, output_tile_size, smoothing_enabled)


func on_render():
	if is_rendering:
		capture_rendered_batch()
		if get_next_tile() != null:
			var progress := int(float(tiles.keys().find(last_mask)) / float(tiles.size()) * 100)
			render_next_batch()
			emit_signal("report_progress", progress)
		else:
			for viewport in render_pool:
				viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
			is_rendering = false
			emit_signal("report_progress", 100)
			emit_signal("tiles_ready")
