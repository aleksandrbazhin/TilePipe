class_name TileRenderer
extends Node


signal tiles_ready()
signal report_progress(progress)

const RENDER_POOL_SIZE = 8

var is_rendering = false
var render_pool := []
var render_progress := 0 # from 0 to 100
var input_tile_parts := {}
var template
var ruleset: Ruleset
var input_tile_size := Vector2.ZERO
var output_tile_size := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var smoothing_enabled := false
var ready = false
var last_mask := -1
# subtiles[mask] = [random_variant1: Image, random_variant2: Image, ...]
var subtiles := {} 


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
		var material: ShaderMaterial = preload("res://src/TileRenderMaterial.tres")
		texture_rect.material = material.duplicate()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		viewport.add_child(texture_rect, true)
		add_child(viewport)


func start_render(tile: TPTile, input_image: Image = null):
	subtiles = tile.result_subtiles_by_bitmask
	ruleset = tile.loaded_ruleset
	input_tile_size = tile.input_tile_size
	output_tile_size = tile.output_tile_size if tile.output_resize else tile.input_tile_size
	input_tile_parts = tile.input_parts
	smoothing_enabled = tile.smoothing
	
	if tile.random_seed_enabled:
		rng.seed = tile.random_seed_value
	else:
		rng.randomize()

	last_mask = subtiles.keys()[0]
	for bitmask in subtiles:
		for subtile in subtiles[bitmask]:
			subtile.reset()
	for viewport in render_pool:
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.size = input_tile_size
		var texture_node = viewport.get_node("TextureRect")
		texture_node.rect_size = input_tile_size
		texture_node.material.set_shader_param("overlay_rate", tile.merge_level.x)
		texture_node.material.set_shader_param("overlap", tile.overlap_level.x)
	render_next_batch()
	is_rendering = true


func setup_subtile_render(bitmask: int, viewport: Viewport):
	var random_center_index: int = rng.randi_range(0, input_tile_parts[0].size() - 1)
	var center_image: Image = input_tile_parts[0][random_center_index]
	var tile_rules_data: Dictionary = ruleset.get_mask_data(bitmask)
	var texture_rect: TextureRect = viewport.get_node("TextureRect")
	if tile_rules_data.empty(): # no ruleset data for mask in template
		var itex = ImageTexture.new()
		itex.create_from_image(center_image, 0)
		return
	var parts_rules: Array = tile_rules_data["part_indexes"]
	var parts_rotations: Array = tile_rules_data["part_rotations"]
	var parts_flips_x: Array = tile_rules_data["part_flip_x"]
	var parts_flips_y: Array = tile_rules_data["part_flip_y"]
	assert (parts_rules.size() == 8 and parts_rotations.size() == 8 and \
			parts_flips_x.size() == 8 and parts_flips_y.size() == 8)
	var itex = ImageTexture.new()
	itex.create_from_image(center_image, 0)
	texture_rect.texture = itex
	var piece_set := [-1, -1, -1, -1, -1, -1, -1, -1]
	var piece_random := [0, 0, 0, 0, 0, 0, 0, 0]
	var mask_index: int = 0
	for mask_name in Const.TILE_MASK:
		var piece_index: int = parts_rules[mask_index]
		var tile_variants: Array = input_tile_parts[piece_index]
		var random_tile_index: int = 0
		var existing_piece_index := piece_set.find(piece_index)
		if existing_piece_index != -1:
			random_tile_index = piece_random[existing_piece_index]
		else:
			random_tile_index = rng.randi_range(0, tile_variants.size() - 1)
			piece_random[mask_index] = random_tile_index
		piece_set[mask_index] = piece_index
		var piece_rot_index: int = parts_rotations[mask_index]
		var rotation_shift: int = Const.ROTATION_SHIFTS.keys()[piece_rot_index]
		var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_shift]["angle"]
		var overlay_image := Image.new()
		overlay_image.copy_from(tile_variants[random_tile_index])
#		if bool(tile_rules_data["part_flip_x"][mask_index]):
#			overlay_image.flip_x()
#		if bool(tile_rules_data["part_flip_y"][mask_index]):
#			overlay_image.flip_y()
		var piece_itex = ImageTexture.new()
		piece_itex.create_from_image(overlay_image, 0)
		var mask_key: int = Const.TILE_MASK[mask_name]
		texture_rect.material.set_shader_param("overlay_texture_%s" % mask_key, piece_itex)
		texture_rect.material.set_shader_param("rotation_%s" % mask_key, -rotation_angle)
		
		var flip_x: bool = bool(parts_flips_x[mask_index])
		var flip_y: bool = bool(parts_flips_y[mask_index])
		
		texture_rect.material.set_shader_param("flip_x_%s" % mask_key, flip_x)
		texture_rect.material.set_shader_param("flip_y_%s" % mask_key, flip_y)
		var overlap_vec: Vector2 = Const.RULESET_PART_OVERLAP_VECTORS[ruleset.parts[piece_index]]
		if overlap_vec.length() == 1.0 and (rotation_angle == PI / 2 or rotation_angle == 3 * PI / 2):
			overlap_vec = overlap_vec.rotated(-PI / 2.0)
		texture_rect.material.set_shader_param("ovelap_direction_%s" % mask_key, overlap_vec)
		mask_index += 1


func render_next_batch():
	for viewport in render_pool:
		var subtile: GeneratedSubTile = get_next_tile()
		if subtile != null:
			last_mask = subtile.bitmask
			subtile.is_rendering = true
			setup_subtile_render(subtile.bitmask, viewport)
			viewport.set_meta("subtile", subtile)
		else:
			viewport.remove_meta("subtile")


func get_next_tile() -> GeneratedSubTile:
	for subtile in subtiles[last_mask]: # remaining subtile variants with last_mask
		if subtile.image == null and not subtile.is_rendering:
			return subtile
	var mask_index := subtiles.keys().find(last_mask)
	if mask_index == subtiles.size() - 1: 
		return null
	var next_mask = subtiles.keys()[mask_index + 1]
	return subtiles[next_mask][0]


func capture_rendered_batch():
	for viewport in render_pool:
		if viewport.has_meta("subtile"):
			var subtile: GeneratedSubTile = viewport.get_meta("subtile")
			var subtile_texture: ViewportTexture = viewport.get_texture()
			subtile.capture_texture(subtile_texture, output_tile_size, smoothing_enabled)


func on_render():
	if is_rendering:
		capture_rendered_batch()
		if get_next_tile() != null:
			var progress := int(float(subtiles.keys().find(last_mask)) / float(subtiles.size()) * 100)
			render_next_batch()
			emit_signal("report_progress", progress)
		else:
			for viewport in render_pool:
				viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
			is_rendering = false
			emit_signal("report_progress", 100)
			emit_signal("tiles_ready")
