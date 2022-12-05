class_name TileRenderer
extends Node


signal subtiles_ready(frame_index)
signal report_progress(progress)

const RENDER_POOL_SIZE = 32

var is_rendering = false
var render_pool := []
var render_progress := 0 # from 0 to 100
var input_tile_parts := {}
var ruleset: Ruleset
var input_tile_size := Vector2.ZERO
var output_tile_size := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var smoothing_enabled := false
var ready = false
var last_mask := -1
# subtiles[mask] = [random_variant1: Image, random_variant2: Image, ...]
var subtiles := {} 
var frame_index := 0
var frame_ref: WeakRef


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


func start_render(tile: TPTile, new_frame_index: int = 0):
	frame_index = new_frame_index
	frame_ref = weakref(tile.frames[new_frame_index])
	subtiles = tile.frames[frame_index].result_subtiles_by_bitmask
	ruleset = tile.ruleset
	input_tile_size = tile.input_tile_size
	output_tile_size = tile.get_output_tile_size()
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
	var frame: TPTileFrame = frame_ref.get_ref()
	if frame == null:
		return
	var tile_rules_data: Dictionary = ruleset.get_mask_data(bitmask)
	if tile_rules_data.empty():
		return
	var texture_rect: TextureRect = viewport.get_node("TextureRect")
	var parts_rules: Array = tile_rules_data["part_indexes"]
	var parts_rotations: Array = tile_rules_data["part_rotations"]
	var parts_flips_x: Array = tile_rules_data["part_flip_x"]
	var parts_flips_y: Array = tile_rules_data["part_flip_y"]
	if not (parts_rules.size() == 9 and parts_rotations.size() == 9 and \
			parts_flips_x.size() == 9 and parts_flips_y.size() == 9):
		return
	var itex = ImageTexture.new()
	itex.create(input_tile_size.x, input_tile_size.y, Image.FORMAT_RGBA8)
	texture_rect.texture = itex

	var part_set := [-1, -1, -1, -1, -1, -1, -1, -1, -1]
	var part_random := [0, 0, 0, 0, 0, 0, 0, 0, 0]
	var mask_index: int = 0
	for mask_name in Const.TILE_MASK:
		var part_index: int = parts_rules[mask_index]
		var part_variants: Array = input_tile_parts[part_index]
		var random_part_index: int = 0
		var existing_part_index := part_set.find(part_index)
		if existing_part_index != -1:
			random_part_index = part_random[existing_part_index]
		else:
			random_part_index = frame.choose_random_part_variant(part_index, 
					part_variants.size(), rng)
			part_random[mask_index] = random_part_index
		part_set[mask_index] = part_index
		var part_rot_index: int = parts_rotations[mask_index]
		var rotation_shift: int = Const.ROTATION_SHIFTS.keys()[part_rot_index]
		var rotation_angle: float = Const.ROTATION_SHIFTS[rotation_shift]["angle"]
		var part_itex = ImageTexture.new()
		part_itex.create_from_image(part_variants[random_part_index], 0)
		var mask_key: int = Const.TILE_MASK[mask_name]
		
		texture_rect.material.set_shader_param("overlay_texture_%s" % mask_key, part_itex)
		texture_rect.material.set_shader_param("rotation_%s" % mask_key, -rotation_angle)
		
		var flip_x: bool = bool(parts_flips_x[mask_index])
		var flip_y: bool = bool(parts_flips_y[mask_index])
		
		texture_rect.material.set_shader_param("flip_x_%s" % mask_key, flip_x)
		texture_rect.material.set_shader_param("flip_y_%s" % mask_key, flip_y)
		var overlap_vec: Vector2 = Ruleset.RULESET_PART_OVERLAP_VECTORS[ruleset.parts[part_index]]
		if overlap_vec.length() == 1.0 and (rotation_angle == PI / 2 or rotation_angle == 3 * PI / 2):
			overlap_vec = overlap_vec.rotated(-PI / 2.0)
		texture_rect.material.set_shader_param("ovelap_direction_%s" % mask_key, overlap_vec)
		mask_index += 1


func render_next_batch():
	for viewport in render_pool:
		var subtile: GeneratedSubTile = get_next_subtile()
		if subtile != null:
			last_mask = subtile.bitmask
			subtile.is_rendering = true
			setup_subtile_render(subtile.bitmask, viewport)
			viewport.set_meta("subtile", subtile)
		else:
			viewport.remove_meta("subtile")


func get_next_subtile() -> GeneratedSubTile:
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
		if get_next_subtile() != null:
			var progress := int(float(subtiles.keys().find(last_mask)) / float(subtiles.size()) * 100)
			render_next_batch()
			emit_signal("report_progress", progress)
		else:
			for viewport in render_pool:
				viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
			is_rendering = false
			emit_signal("report_progress", 100)
			emit_signal("subtiles_ready", frame_index)
