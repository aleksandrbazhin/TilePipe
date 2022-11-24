extends PanelContainer

class_name FramePartsContainer


func clear():
	for column in $HBoxContainer/ScrollContainer/PartsContainer.get_children():
		column.queue_free()
	for row_control in $HBoxContainer/RowControlsContainer.get_children():
		row_control.queue_free()


func populate_from_tile(tile: TPTile, frame_index: int = 1):
	var ruleset_parts := tile.loaded_ruleset.parts
	var max_variants_number := 0
	for part_index in tile.input_parts:
		if part_index >= ruleset_parts.size():
			break
		var variants_column := FrameColumnVariants.new()
		variants_column.add_constant_override("separation", 2)
		var total_priority := 0
		for part in tile.input_parts[part_index]:
			var part_control: PartFrameControl = preload("res://src/nodes/PartFrameControl.tscn").instance()
			var part_variant_random_priority = tile.get_part_frame_random_priority(
					frame_index, part_index, part.variant_index)
			part_control.setup( ruleset_parts[part.part_index],  part, 
					part_variant_random_priority, tile.input_parts[part_index].size())
			total_priority += part_control.random_priority
			variants_column.add_child(part_control)
			part_control.connect("random_priority_changed", self, "on_part_priority_change", 
					[variants_column, frame_index, part_index, part.variant_index])
		variants_column.set_parts_total_priority(total_priority)
		$HBoxContainer/ScrollContainer/PartsContainer.add_child(variants_column)
		$HBoxContainer/Control/Label.text = "Frame " + str(frame_index)
		if max_variants_number < tile.input_parts[part_index].size():
			max_variants_number = tile.input_parts[part_index].size()
	for v_index in range(max_variants_number):
		var row_control := preload("res://FramePartsRowControl.tscn").instance()
		if max_variants_number == 1:
			row_control.block()
		$HBoxContainer/RowControlsContainer.add_child(row_control)
		row_control.connect("toggled", self, "on_row_control_change", [v_index])


func on_row_control_change(is_row_enabled: bool, variant_index: int):
	var parts_change_count := 0
	for column in $HBoxContainer/ScrollContainer/PartsContainer.get_children():
		if column.enable_variant_by_index(variant_index, is_row_enabled):
			parts_change_count += 1
	if parts_change_count == 0:
		$HBoxContainer/RowControlsContainer.get_child(variant_index).set_enabled_quietly(true)


func on_part_priority_change(part: PartFrameControl, column: FrameColumnVariants,
		frame_index: int, part_index: int, variant_index: int):
	State.update_tile_param(TPTile.PARAM_FRAME_RANDOM_PRIORITIES, 
			[frame_index, part_index, variant_index, part.random_priority])
#	print("NEW_PRIORITY ", part.random_priority)
	column.recalculate_parts_total_priority()
	
	
	
