extends PanelContainer

class_name FramePartsContainer


#onready var parts_container := $ScrollContainer/PartsContainer


func clear():
	for part in $ScrollContainer/PartsContainer.get_children():
		part.queue_free()


func populate_from_tile(tile: TPTile):
	var ruleset_parts := tile.loaded_ruleset.parts
	for part_index in tile.input_parts:
		if part_index >= ruleset_parts.size():
			break
		var frames_container := VBoxContainer.new()

		frames_container.add_constant_override("separation", 2)
		for part in tile.input_parts[part_index]:
			var frame_control: PartFrameControl = preload("res://src/nodes/PartFrameControl.tscn").instance()
			frame_control.setup(ruleset_parts[part.part_index], part, 1, tile.input_parts[part_index].size())
			frames_container.add_child(frame_control)
#			frame_control.connect("part_frequency_click", self, "on_part_frequency_edit_start")
		$ScrollContainer/PartsContainer.add_child(frames_container)
