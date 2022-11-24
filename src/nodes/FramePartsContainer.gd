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
		var frames_container := FrameColumnVariants.new()
		frames_container.add_constant_override("separation", 2)
		var total_priority := 0
		for part in tile.input_parts[part_index]:
			var frame_control: PartFrameControl = preload("res://src/nodes/PartFrameControl.tscn").instance()
#			print(tile.get_part_frame_random_priority(frame_index, part_index, part.variant_index))
			frame_control.setup(
				ruleset_parts[part.part_index], 
				part, 
				tile.get_part_frame_random_priority(frame_index, part_index, part.variant_index),
				tile.input_parts[part_index].size())
			total_priority += frame_control.random_priority
			frames_container.add_child(frame_control)
#			frame_control.connect("random_priority_changed", frames_container, "recalculate_parts_total_priority")
			frame_control.connect("random_priority_changed", self, "on_part_priority_change", [frames_container])
		frames_container.set_parts_total_priority(total_priority)
		$HBoxContainer/ScrollContainer/PartsContainer.add_child(frames_container)
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


func on_part_priority_change(part: PartFrameControl, column: FrameColumnVariants):
	column.recalculate_parts_total_priority()
