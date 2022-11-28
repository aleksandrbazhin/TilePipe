class_name FrameColumnVariants
extends VBoxContainer


func compute_parts_total_priority() -> int:
	var total := 0
	for part_control in get_children():
		total += part_control.random_priority if part_control.is_enabled else 0
	return total


func set_parts_total_priority(total: int):
	for part in get_children():
		part.set_total_random_priority(total)


func recalculate_parts_total_priority():
	set_parts_total_priority(compute_parts_total_priority())


func enable_variant_by_index(index: int, is_enabled: bool, suppress_render: bool = false) -> bool:
	var part_control: PartFrameControl = get_child(index)
	if is_enabled:
		if part_control.enable(suppress_render):
			return true
	else:
		if part_control.disable(suppress_render):
			return true
	return false
