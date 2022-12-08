class_name ScalableTextureContainer
extends Control


signal tile_size_changed(size)

var current_tile_size: Vector2
var current_scale := Vector2.ONE
var is_ready := false
var is_highlighting_tile := false
var highlight_position := Vector2.ZERO
var highlight_part_id := 0

onready var bg_rect := $BGTextureRect
onready var texture_rect := $TextureRect
onready var x_spinbox: AdvancedSpinBox = $InputInfo/HBoxContainer/XSpinBox
onready var y_spinbox: AdvancedSpinBox = $InputInfo/HBoxContainer/YSpinBox
onready var highlight_contaoner := $Highlights


func _ready():
	is_ready = true


func clear():
	texture_rect.texture = null
	current_tile_size = Vector2.ZERO


func set_main_texture(texture: Texture):
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	texture_rect.texture = texture
	set_input_tile_size(tile.input_tile_size)
	setup_size_display(tile.input_tile_size)


# we need to resize input texture precisely, so find the lower 
# power of 2 that fits into the display zone
# first we find what fits, then scale both texture and background
func set_input_tile_size(tile_size: Vector2):
	current_tile_size = tile_size
	yield(get_tree(), "idle_frame")
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
	x_spinbox.set_value_quietly(tile_size.x)
	y_spinbox.set_value_quietly(tile_size.y)


func set_part_highlight(part_id: int, is_on: bool, tile: TPTile = null):
	if part_id == highlight_part_id and is_on == is_highlighting_tile:
		return
	if tile == null:
		return
	if not is_on:
		for highlight in highlight_contaoner.get_children():
			highlight.free()
		return
	if not (part_id - 1) in tile.input_parts:
		return
	var tile_size := current_scale * current_tile_size
	for part in tile.input_parts[part_id - 1]:
		var highlight := TextureRect.new()
		highlight.rect_position = Vector2(part.part_index, part.variant_index) * tile_size
		highlight.rect_size = tile_size
		highlight.expand = true
		highlight.texture = Ruleset.PART_HIGHLIGHT_MASKS[part.ruleset_part_index]
		highlight_contaoner.add_child(highlight)


func _draw():
	#TODO: redraws multiple times on startup
	if is_ready:
		set_input_tile_size(current_tile_size)


func _on_XSpinBox_value_changed_no_silence(value):
	current_tile_size.y = value
	current_tile_size.x = value
	emit_signal("tile_size_changed", current_tile_size)
	update()


func _on_YSpinBox_value_changed_no_silence(value):
	current_tile_size.y = value
	emit_signal("tile_size_changed", current_tile_size)
	update()
