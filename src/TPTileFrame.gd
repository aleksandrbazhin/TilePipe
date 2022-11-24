extends Reference

class_name TPTileFrame

var parsed_template := {}
var result_subtiles_by_bitmask := {}
var result_texture: Texture
var index := 0
# this is a dictionary of a form
# {part_index : {variant_index1: variant1_priority, vvarinat_index2: variant2_priority, ...}, ...}
var part_random_priorities := {}


func _init(new_index):
	index = new_index


func is_variant_row_disabled(variant_index: int) -> bool:
	var count := 0
	for part_index in part_random_priorities:
		if not variant_index in part_random_priorities[part_index]:
			return false
		else:
			count += part_random_priorities[part_index][variant_index]
	return count == 0


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
	var result := 0
	var random_value := rng.randi_range(0, total_probabilities)
	for variant_index in max_variants:
		if variant_index in variants:
			random_value -= variants[variant_index]
		else:
			random_value -= 1
		if random_value <= 0:
			result = variant_index
			break
	return result


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


func set_result_texture(tex: Texture):
	result_texture = tex
