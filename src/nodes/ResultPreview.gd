extends ColorRect

class_name ResultView

export var single_tile_visible := true
export var controls_visible := true

onready var single_tile := $VBoxContainer/HSplitContainer/SingleTile
onready var result_texture := $VBoxContainer/HSplitContainer/Result/TextureRect
onready var controls := $VBoxContainer/HSplitContainer/Result/ImageSettings


func _ready():
	if not single_tile_visible:
		single_tile.hide()
	if not controls_visible:
		controls.hide()


func set_result_image(image: Image):
	var itex := ImageTexture.new()
	itex.create_from_image(image)
	result_texture.texture = itex
