extends TileSet

class_name TilesheetDescrption

const GODOT_MASK: Dictionary = {
	"TOP_LEFT": 1,
	"TOP": 2,
	"TOP_RIGHT": 4,
	"LEFT": 8,
	"CENTER": 16,
	"RIGHT": 32,
	"BOTTOM_LEFT": 64,
	"BOTTOM": 128,
	"BOTTOM_RIGHT": 256
}

export var replacements_table: Dictionary = {}

func get_my_autotile_ignore_corners_mask(mask: int) -> int:
	mask &= ~GODOT_MASK["CENTER"]
	if mask & ~GODOT_MASK["TOP"] == mask or mask & ~GODOT_MASK["LEFT"] == mask:
		mask &= ~GODOT_MASK["TOP_LEFT"]
	if mask & ~GODOT_MASK["BOTTOM"] == mask or mask & ~GODOT_MASK["LEFT"] == mask:
		mask &= ~GODOT_MASK["BOTTOM_LEFT"]
	if mask & ~GODOT_MASK["TOP"] == mask or mask & ~GODOT_MASK["RIGHT"] == mask:
		mask &= ~GODOT_MASK["TOP_RIGHT"]
	if mask & ~GODOT_MASK["BOTTOM"] == mask or mask & ~GODOT_MASK["RIGHT"] == mask:
		mask &= ~GODOT_MASK["BOTTOM_RIGHT"]
	return mask | GODOT_MASK["CENTER"]

func get_autotile_by_mask(mask: int) -> int:
	if replacements_table.has(mask):
		return find_tile_by_name(replacements_table[mask])
	return 0
#	for mask in tileset_description.replacements_table:
#		island_bitmask_tile_table[mask] = tile_set.find_tile_by_name(
#			tileset_description.replacements_table[mask])
