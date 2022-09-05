class_name RuleInRuleset
extends PanelContainer


func setup(ruleset: Ruleset, tile_index: int):
	var tile_data = ruleset.get_subtiles()[tile_index]
	var masks_container := $BoxContainer/NeighborMasks/ScrollContainer/HBoxContainer
	for mask_value in tile_data["mask_variants"]:
		var mask_node := TileMaskPreview.new(mask_value)
		masks_container.add_child_below_node(masks_container.get_child(0), mask_node)
	$BoxContainer/Label.text = str(tile_index + 1)
	$BoxContainer/Preview/Parts/CenterContainer/TileCompositionPreview.setup(tile_data["part_indexes"])
	$BoxContainer/Preview/Rotations/CenterContainer/TileRotationsPreview.setup(tile_data["part_rotations"])
	$BoxContainer/Preview/Flips/CenterContainer/TileFlipsPreview.setup(tile_data["part_flip_x"], tile_data["part_flip_y"])
	$BoxContainer/RawData.text = ruleset.get_raw_tile_data(tile_index)
