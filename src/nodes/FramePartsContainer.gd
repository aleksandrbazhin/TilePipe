extends PanelContainer

class_name FramePartsContainer


func clear():
	for part in $ScrollContainer/PartsContainer.get_children():
		part.queue_free()


func populate_from_tile(tile: TPTile):
	var ruleset_parts := tile.loaded_ruleset.parts
	for part_index in tile.input_parts:
		if part_index >= ruleset_parts.size():
			break
		var frames_container := FrameColumnVariants.new()
		frames_container.add_constant_override("separation", 2)
		for part in tile.input_parts[part_index]:
			var frame_control: PartFrameControl = preload("res://src/nodes/PartFrameControl.tscn").instance()
			frame_control.setup(ruleset_parts[part.part_index], part, 1, tile.input_parts[part_index].size())
			frames_container.add_child(frame_control)
			frame_control.connect("random_priority_changed", frames_container, "recalculate_parts_total_priority")
		frames_container.recalculate_parts_total_priority()
		$ScrollContainer/PartsContainer.add_child(frames_container)


func hide_all_random_controls():
	for container in $ScrollContainer/PartsContainer.get_children():
		for part_control in container.get_children():
#			print(part_control)
			part_control.hide_random_controls()

#
#func _unhandled_input(event):
#	print(2)
#	if event is InputEventMouseButton or event is InputEventMouseMotion:
#		hide_all_random_controls()
#
#func _on_FramePartsContainer_gui_input(event):
#	print(event)
#	if event is InputEventMouseButton and event.pressed:
#		print(event)
#		hide_all_random_controls()
