extends VBoxContainer

class_name TileInRuleset

func setup(ruleset: Ruleset, tile_index: int):
	var tile_data = ruleset.get_tiles()[tile_index]
	var masks_container := $TilesMasks/ScrollContainer/HBoxContainer	
	for mask_value in tile_data["mask_variants"]:
		var mask_node := TileMaskPreview.new(mask_value)
		masks_container.add_child(mask_node)
	$HBoxContainer/Parts/TileCompositionPreview.setup(tile_data["part_indexes"])
	$HBoxContainer/Rotations/TileRotationsPreview.setup(tile_data["part_rotations"])
	$HBoxContainer/Flips/TileFlipsPreview.setup(tile_data["part_flip_x"], tile_data["part_flip_y"])
