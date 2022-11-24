extends Reference

class_name TPTileFrame

var parsed_template := {}
var result_subtiles_by_bitmask := {}
var result_texture: Texture
var index := 0
# this is a dictionary of a form
# {part_index : {varinat_index1: variant1_priority, vvarinat_index2: variant2_priority, ...}, ...}
var part_random_priorities := {}


func _init(new_index):
	index = new_index


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
#


func append_subtile(mask: int, pos: Vector2):
	if not result_subtiles_by_bitmask.has(mask):
		result_subtiles_by_bitmask[mask] = []
	var subtile := GeneratedSubTile.new(mask, pos)
	result_subtiles_by_bitmask[mask].append(subtile)
	parsed_template[pos] = weakref(subtile)


func set_result_texture(tex: Texture):
	result_texture = tex
