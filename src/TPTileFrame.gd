class_name TPTileFrame
extends Reference

# {subtile_position: weakref(Subtile)} 
var parsed_template := {}
var result_subtiles_by_bitmask := {}
var result_texture: Texture
var index := 0
# {part_index : {variant_index1: variant1_priority, vvarinat_index2: variant2_priority, ...}, ...}
var part_random_priorities := {}


func _init(new_index):
	index = new_index


func get_subtile_count() -> int:
	return parsed_template.size()


func is_variant_row_disabled(variant_index: int) -> bool:
	var enabled_variants_count := 0
	var parts_count := 0
	for part_index in part_random_priorities:
		parts_count += 1
		if not variant_index in part_random_priorities[part_index]:
			return false
		else:
			enabled_variants_count += part_random_priorities[part_index][variant_index]
	if parts_count == 0:
		return false
	return enabled_variants_count == 0


func choose_random_part_variant(part_index: int, max_variants: int, 
		rng: RandomNumberGenerator) -> int:
	if not part_index in part_random_priorities:
		return rng.randi_range(0, max_variants - 1)
	var variants: Dictionary = part_random_priorities[part_index]
	var total_probabilities := 0
	for variant_index in max_variants:
		if variant_index in variants:
			total_probabilities += variants[variant_index]
		else:
			total_probabilities += 1
	var acc := 0
	var random_value := rng.randi_range(0, total_probabilities - 1)
	for variant_index in max_variants:
		if variant_index in variants:
			acc += variants[variant_index]
		else:
			acc += 1
		if acc > random_value:
			return variant_index
	return 0


func get_part_priority(part_index: int, variant_index: int) -> int:
	if not part_index in part_random_priorities:
		return 1
	if not variant_index in part_random_priorities[part_index]:
		return 1
	return part_random_priorities[part_index][variant_index]


func set_part_priority(part_index: int, variant_index: int, priority: int):
	if not part_index in part_random_priorities:
		part_random_priorities[part_index] = {}
	part_random_priorities[part_index][variant_index] = priority


func append_subtile(mask: int, pos: Vector2):
	if not result_subtiles_by_bitmask.has(mask):
		result_subtiles_by_bitmask[mask] = []
	var subtile := GeneratedSubTile.new(mask, pos)
	result_subtiles_by_bitmask[mask].append(subtile)
	parsed_template[pos] = weakref(subtile)

#
#func set_result_texture(tex: Texture):
#	result_texture = tex


func clear():
	result_texture = null
	for mask in result_subtiles_by_bitmask:
		for variant in result_subtiles_by_bitmask[mask]:
			variant.reset()


func get_first_subtile() -> GeneratedSubTile:
	if result_subtiles_by_bitmask.empty():
		return null
	var first_subtile_key = result_subtiles_by_bitmask.keys()[0]
	if result_subtiles_by_bitmask[first_subtile_key].size() == 0:
		return null
	return result_subtiles_by_bitmask[first_subtile_key][0]


func merge_result_from_subtiles(template_size: Vector2, tile_size: Vector2, 
		subtile_spacing: Vector2 = Vector2.ZERO):
	var subtiles_by_bitmasks: Dictionary = result_subtiles_by_bitmask
	if subtiles_by_bitmasks.empty():
		return
	var out_image := Image.new()
	var out_image_size: Vector2 = template_size * tile_size
	out_image_size += (template_size - Vector2.ONE) * subtile_spacing
	out_image.create(int(out_image_size.x), int(out_image_size.y), false, Image.FORMAT_RGBA8)
	var tile_rect := Rect2(Vector2.ZERO, tile_size)
	var itex = ImageTexture.new()
	itex.create_from_image(out_image, 0)
	for mask in subtiles_by_bitmasks.keys():
		for tile_variant_index in range(subtiles_by_bitmasks[mask].size()):
			var subtile: GeneratedSubTile = subtiles_by_bitmasks[mask][tile_variant_index]
			var tile_position: Vector2 = subtile.position_in_template * tile_size
			tile_position +=  subtile.position_in_template * subtile_spacing
			if subtile.image == null:
				continue
			out_image.blit_rect(subtile.image, tile_rect, tile_position)
			itex.set_data(out_image)
#	set_result_texture(itex)
	result_texture = itex
