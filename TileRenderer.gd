extends Node

class_name TileRenderer

signal tiles_ready()
signal report_progress(done_percent)

const RENDER_POOL_SIZE = 32


var is_rendering = false
var render_pool := []

var render_progress := 0 # from 0 to 100
var input_tile_parts := {}
var template
var ruleset: GenerationData
var input_tile_size := Vector2.ZERO
var output_tile_size := Vector2.ZERO
#var overlap_rate := 0.5
#var merge_rate := 0.5
var rng: RandomNumberGenerator
var smoothing_enabled := false
var resize_factor
var ready = false
var last_mask := 0
# tiles[mask] = [random_variant1, random_variant2, ...]
var tiles := {} 


func _ready():
	VisualServer.connect("frame_post_draw", self, "on_render")
	init_render_pool()
	ready = true


func init_render_pool():
#	print(ready)
	for _i in range(RENDER_POOL_SIZE):
		var viewport := Viewport.new()
		render_pool.append(viewport)
		viewport.transparent_bg = true
		viewport.disable_3d = true
		viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
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
			part.create(input_tile_size.x, input_tile_size.y, false, Image.FORMAT_RGBA8)
			if input_tile_size.y + variant_index * input_tile_size.y > input_image.get_size().y:
				break
			var copy_rect := Rect2(part_index * input_tile_size.x, variant_index * input_tile_size.y, 
				input_tile_size.x, input_tile_size.y)
			part.blit_rect(input_image, copy_rect, Vector2.ZERO)
			if part.is_empty():
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
	
	var pieces_rules: Array = tile_rules_data["generate_piece_indexes"]
	var pieces_rotations: Array = tile_rules_data["generate_piece_rotations"]
	assert (pieces_rules.size() == 8 && pieces_rotations.size() == 8)
	
	var itex = ImageTexture.new()
	itex.create_from_image(center_image, 0)
	var texture_rect: TextureRect = viewport.get_node("TextureRect")
	texture_rect.texture = itex
#	print(mask)
	var mask_index: int = 0
	for mask_name in Const.TILE_MASK:
		var piece_index: int = pieces_rules[mask_index]
#		print(mask_name, " ", piece_index)
		var random_tile_index: int = rng.randi_range(0, input_tile_parts[piece_index].size() - 1)
		var piece_rot_index: int = pieces_rotations[mask_index]
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
	
	
#	var tile := Image.new()
#	tile.create(int(input_tile_size.x), int(input_tile_size.y), false, Image.FORMAT_RGBA8)
#	tile.blit_rect(input_tile_parts[0][0], Rect2(0, 0, input_tile_size.x, input_tile_size.y), Vector2.ZERO)
#	var itex := ImageTexture.new()
#	itex.create_from_image(tile)
#	return itex


func render_next_batch():
	for viewport in render_pool:
		var tile: GeneratedTile = get_next_tile()
		if tile != null:
			last_mask = tile.mask
			tile.is_rendering = true
			setup_tile_render(tile.mask, viewport)
#			viewport.get_node("TextureRect").texture = create_tile(tile.mask)
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
	# TODO: переделать размер на вектор
	var resize_factor: float = float(output_tile_size.x) / float(input_tile_size.x)
	for viewport in render_pool:
		var tile_texture: ViewportTexture = viewport.get_texture()
		var image := Image.new()
		image.create(int(input_tile_size.x), int(input_tile_size.y), false, Image.FORMAT_RGBA8)
		image.blit_rect(
			tile_texture.get_data(),
			Rect2(Vector2.ZERO, input_tile_size), 
			Vector2.ZERO)
		if resize_factor != 1.0:
			var interpolation: int = Image.INTERPOLATE_NEAREST if not smoothing_enabled else Image.INTERPOLATE_TRILINEAR
			image.resize(output_tile_size.x, output_tile_size.y, interpolation)
		if viewport.has_meta("tile") :
			var tile: GeneratedTile = viewport.get_meta("tile")
			tile.image = image


func get_template_random_variants(_mask: int):
	return 1


func on_render():
	if is_rendering:
#		var total_tiles: int = 256#ruleset.data["data"].size()
#		print(tiles.size() , "  ", total_tiles)
		capture_rendered_batch()
		emit_signal("tiles_ready")
#		var last_mask: int = int(ruleset.get_ruleset()[-1]["mask_variants"][-1])
#		print("last_mask: ", last_mask)
#		if tiles.has(last_mask) and tiles[last_mask].size() == get_template_random_variants(last_mask):
##		if tiles.size() < total_tiles:
#			render_next_batch()
#			emit_signal("report_progress", render_progress)
#		else:
#			emit_signal("report_progress", 100)
#			is_rendering = false
#			emit_signal("tiles_ready")


	
	


