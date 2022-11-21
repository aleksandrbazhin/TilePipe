extends VBoxContainer


class_name FrameColumnVariants


func compute_parts_total_priority() -> int:
	var total := 0
	for part in get_children():
		total += part.random_priority
	return total


func set_parts_total_priority(total: int):
	for part in get_children():
		part.set_total_random_priority(total)


func recalculate_parts_total_priority():
	set_parts_total_priority(compute_parts_total_priority())
