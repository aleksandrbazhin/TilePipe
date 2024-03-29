class_name PartFrameControl
extends TextureRect


signal random_priority_changed(self_, suppress_render)

const RANDOM_ICON_POSITION := Vector2(4, 29)
export var BG_COLOR := Color(0.3, 0.4, 0.4, 0.5)
export var BG_COLOR2 := Color(0.3, 0.4, 0.4, 0.5)


var part_type: int = Ruleset.RULESET_TILE_PARTS.FULL
var random_variant: int = 0
var random_priority: int = 1
var frame_index: int = 0
var total_random_priority: int = 1
var max_frames: int = 1
var part_ref: WeakRef
var is_enabled := true

# [before ready]
func setup(new_part_type: int, part: TilePart, new_random_priority: int = 1, new_total_prority: int = 1):
	part_type = new_part_type
	part_ref = weakref(part)
	random_variant = part.variant_index
	random_priority = new_random_priority
	if random_priority == 0:
		$BlockingOverlay.show()
		is_enabled = false
	total_random_priority = new_total_prority
	var itex := ImageTexture.new()
	if not part.is_empty():
		itex.create_from_image(part, 0)
		itex.set_size_override(rect_size)
		texture = itex
	else:
		texture = Ruleset.RULESET_PART_TEXTURES[part_type]


func get_part_variant_index() -> int:
	var result := 0
	if part_ref != null:
		var part: TilePart = part_ref.get_ref()
		result = part.variant_index
	return result


func draw_labels():	
	hint_tooltip = "Part variant " + str(random_variant + 1) + " with randomization priority: " + str(random_priority) 
	$RandomLabel.text = str(random_priority) + "/" + str(total_random_priority)  


func update_info():
	draw_labels()
	update()


func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_size), BG_COLOR)
	draw_rect(Rect2(Vector2(1, 25), Vector2(46, 22)), BG_COLOR2)


func set_total_random_priority(value: int):
	total_random_priority = value
	$RandomLabel.text = str(random_priority) + "/" + str(total_random_priority)


func enable(suppress_render: bool = false) -> bool:
	$BlockingOverlay.hide()
	if not is_enabled:
		if random_priority == 0:
			random_priority = 1
		is_enabled = true
		emit_signal("random_priority_changed", self, suppress_render)
		return true
	return false


func disable(suppress_render: bool = false) -> bool:
	if random_priority > 0 and float(total_random_priority) / float(random_priority) > 1 and is_enabled:
		$BlockingOverlay.show()
		is_enabled = false
		random_priority = 0
		emit_signal("random_priority_changed", self, suppress_render)
		return true
	return false


func _on_PartFrameControl_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if event.position.y < rect_size.y / 1.55 and is_enabled:
			disable()


func _on_TextureRect_gui_input(event):	
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if event.position.y > $SpinRect.rect_size.y / 2:
			if random_priority <= 1:
				return
			random_priority -= 1
		else:
			random_priority += 1
		emit_signal("random_priority_changed", self, false)


func _on_BlockingOverlay_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if not is_enabled:
			enable()
