extends VBoxContainer

class_name TileMainView

onready var title := $Title/Label
onready var input_title := $MarginContainer/VBoxContainer/InputContainer/HBoxContainer/FileName
onready var input_texture := $MarginContainer/VBoxContainer/InputContainer/TextureRect
onready var ruleset_title := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/HBoxContainer/FileName
onready var ruleset_texture := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/TextureRect
onready var template_title := $MarginContainer/VBoxContainer/TemplateContainer/HBoxContainer/FileName
onready var template_texture := $MarginContainer/VBoxContainer/TemplateContainer/TextureRect


#func _ready():
#	print("ready")
#	get_tree().get_root().connect("size_changed", self, "set_texture_scale_mode")
#
#
#func set_texture_scale_mode(test_size := Vector2.ZERO):
#	print("scale", input_texture.texture.get_size().x, " ", input_texture.rect_size.x)
#	if input_texture.texture.get_size().x < input_texture.rect_size.x:
#		input_texture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
#	else:
#		input_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
#

func load_data(tile: TileInTree):
	title.text = tile.tile_file_name
	if tile.texture_path != "":
		input_title.text = tile.texture_path.get_file()
		input_texture.texture = tile.loaded_texture
#		set_texture_scale_mode()
	if tile.template_path != "":
		template_title.text = tile.template_path.get_file()
		template_texture.texture = tile.loaded_template
	if tile.loaded_ruleset.is_loaded:
		ruleset_title.text = tile.ruleset_path.get_file()
