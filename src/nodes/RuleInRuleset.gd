class_name RuleInRuleset
extends ColorRect


const DEFAULT_COLoR := Color(0.0, 0.0, 0.0, 0.2)
const SELECT_COLoR := Color(0.9, 0.9, 0.9, 0.2)

var bitmask_variants: Array

# [before ready]
func setup(ruleset: Ruleset, tile_index: int):
	var tile_data = ruleset.get_subtiles()[tile_index]
	var masks_container := $BoxContainer/NeighborMasks/ScrollContainer/HBoxContainer
	for mask_value in tile_data["mask_variants"]:
		var mask_node := TileMaskPreview.new(mask_value)
		masks_container.add_child_below_node(masks_container.get_child(0), mask_node)
		bitmask_variants.append(mask_value)
#	$BoxContainer/Label.text = str(tile_index + 1)
	$BoxContainer/Preview/Parts/CenterContainer/TileCompositionPreview.setup(tile_data["part_indexes"])
	$BoxContainer/Preview/Rotations/CenterContainer/TileRotationsPreview.setup(tile_data["part_rotations"])
	$BoxContainer/Preview/Flips/CenterContainer/TileFlipsPreview.setup(tile_data["part_flip_x"], tile_data["part_flip_y"])
	$BoxContainer/RawData.text = ruleset.get_raw_tile_data(tile_index)
	color = DEFAULT_COLoR


func select():
	color = SELECT_COLoR


func deselect():
	color = DEFAULT_COLoR
