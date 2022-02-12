extends VBoxContainer

class_name TileInRuleset

func setup(ruleset: Ruleset, tile_index: int):
	var tile_data = ruleset.get_tiles()[tile_index]
	var masks_container := $Data/MarginContainer/HBox/Preview/TilesMasks/ScrollContainer/HBoxContainer
	for mask_value in tile_data["mask_variants"]:
		var mask_node := TileMaskPreview.new(mask_value)
		masks_container.add_child(mask_node)
	$Data/MarginContainer/HBox/Preview/HBox/Parts/CenterContainer/TileCompositionPreview.setup(tile_data["part_indexes"])
	$Data/MarginContainer/HBox/Preview/HBox/Rotations/CenterContainer/TileRotationsPreview.setup(tile_data["part_rotations"])
	$Data/MarginContainer/HBox/Preview/HBox/Flips/CenterContainer/TileFlipsPreview.setup(tile_data["part_flip_x"], tile_data["part_flip_y"])
	$Label.text = "Tile " + str(tile_index + 1)
	$Data/MarginContainer/HBox/RawData.text = ruleset.get_raw_tile_data(tile_index)
