class_name PartFrameControl
extends TextureRect


signal random_priority_changed()


#const RANDOM_ICON_POSITION := Vector2(4, 6)
const RANDOM_ICON_POSITION := Vector2(4, 29)
#const FRAME_ICON_POSITION := Vector2(4, 26)
export var BG_COLOR := Color(0.3, 0.4, 0.4, 0.5)
export var BG_COLOR2 := Color(0.3, 0.4, 0.4, 0.5)

# TODO: если нет рандомизации (макс рандом ные варианты == 1), то писать No вместо рандом лейбла
# TODO: делить на 2 все варианты при выборе количества фреймов
# TODO: переделать контрол со скролла на spinbox

var part_type: int = Ruleset.RULESET_TILE_PARTS.FULL
var random_variant: int = 0
var random_priority: int = 1 
var frame_index: int = 0
var total_random_priority: int = 1
var max_frames: int = 1
var part_ref: WeakRef

onready var random_label: Label = $RandomLabel


func _ready():
	$RandomSpinBox.rect_size = Vector2.ONE
#	draw_labels()


func setup(new_part_type: int, part: TilePart, new_random_priority: int = 1, new_total_prority: int = 1):
	part_type = new_part_type
	part_ref = weakref(part)
	random_variant = part.variant_index
	random_priority = new_random_priority
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
	random_label.text = str(random_priority) + "/" + str(total_random_priority)  


func update_info():
	draw_labels()
	update()


func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_size), BG_COLOR)
	draw_rect(Rect2(Vector2(1, 25), Vector2(46, 22)), BG_COLOR2)


func _on_PartFrameControl_gui_input(event: InputEvent):
	pass


func _on_RandomLabel_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		get_tree().set_input_as_handled()		
		$RandomLabel.hide()
		var el: AdvancedSpinBox = $RandomSpinBox
		el.show()
		el.value = random_priority
		el.suffix = "/" + str(total_random_priority)
#		el.focus_mode = Control.FOCUS_ALL
#		el.grab_focus()


func _on_PartFrameControl_mouse_exited():
	hide_random_controls()


func hide_random_controls():
	$RandomSpinBox.hide()
	var el := $RandomLabel
	el.text = str(random_priority) + "/" + str(total_random_priority)
	el.show()


func _on_RandomSpinBox_mouse_exited():
	hide_random_controls()


func _on_RandomSpinBox_value_changed_no_silence(value):
	random_priority = int(value)
	emit_signal("random_priority_changed")


func set_total_random_priority(value: int):
	total_random_priority = value
	$RandomSpinBox.suffix = "/" + str(total_random_priority)
	$RandomLabel.text = str(random_priority) + "/" + str(total_random_priority)
	
