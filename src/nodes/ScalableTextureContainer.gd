extends Control

class_name ScalableTextureContainer


signal tile_size_changed(size)

var current_tile_size: Vector2
var current_scale := Vector2.ONE
var is_ready := false
var is_highlighting_tile := false
var highlight_position := Vector2.ZERO
var highlight_part_id := 0

onready var bg_rect := $BGTextureRect
onready var texture_rect := $TextureRect
onready var x_spinbox := $InputInfo/HBoxContainer/XSpinBox
onready var y_spinbox := $InputInfo/HBoxContainer/YSpinBox
onready var part_highlight := $PartHihglight


func _ready():
	is_ready = true


func set_main_texture(texture: Texture, tile_size: Vector2 = Const.DEFAULT_TILE_SIZE):
	texture_rect.texture = texture
	current_tile_size = tile_size
	set_input_tile_size(tile_size)


# we need to resize input texture precisely, so find the lower 
# power of 2 that fits into the display zone
# first we find what fits, then scale both texture and background
func set_input_tile_size(tile_size: Vector2):
	yield(get_tree(), "idle_frame")
	setup_size_display(tile_size)
	if texture_rect.texture == null:
		return
	var input_size: Vector2 = texture_rect.texture.get_size()
	var x_scale: float = rect_size.x / input_size.x
	var y_scale: float = rect_size.y / input_size.y
	var scale_factor: float = min(x_scale, y_scale)
	scale_factor = Helpers.snap_down_to_po2(scale_factor)
	current_scale = Vector2(scale_factor, scale_factor)
	texture_rect.rect_scale = current_scale
	texture_rect.rect_size /= current_scale
	var bg_scale := scale_factor * tile_size / Const.DEFAULT_TILE_SIZE
	bg_rect.rect_size = rect_size / bg_scale
	bg_rect.rect_scale = bg_scale


func setup_size_display(tile_size: Vector2):
	x_spinbox.value = tile_size.x
	y_spinbox.value = tile_size.y


func set_part_highlight(part_id: int, is_on: bool):
	# TODO: search highlighted part by position set in ruleset or tile settings
	if part_id == highlight_part_id and is_on == is_highlighting_tile:
		return
	if is_on:
		part_highlight.show()
		highlight_position = Vector2(part_id - 1, 0)
		var color_index := (part_id - 1) % Const.HIGHLIGHT_COLORS.size()
		part_highlight.color = Const.HIGHLIGHT_COLORS[color_index]
		part_highlight.color.a = 0.6
	else:
		part_highlight.hide()
	is_highlighting_tile = is_on
	draw_part_highlight()


func draw_part_highlight():
	if is_highlighting_tile:
		var tile_size := current_scale * current_tile_size
		part_highlight.rect_position = highlight_position * tile_size
		part_highlight.rect_size = tile_size


func _draw():
	#TODO: redraws 2 times instead of one
	if is_ready:
		set_input_tile_size(current_tile_size)
		draw_part_highlight()


func _on_XSpinBox_value_changed(value: float):
	var is_square := current_tile_size.x == current_tile_size.y
	current_tile_size.x = value
	if is_square:
		y_spinbox.value = x_spinbox.value
	else:
		emit_signal("tile_size_changed", current_tile_size)
		update()


func _on_YSpinBox_value_changed(value: float):
	current_tile_size.y = value
	emit_signal("tile_size_changed", current_tile_size)
	update()
