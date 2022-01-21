extends VBoxContainer

class_name TileMainView

onready var title := $Title/Label
onready var input_title := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/InputContainer/HBoxContainer/FileName
onready var input_texture := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/InputContainer/TextureRect
onready var ruleset_title := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/HBoxContainer/FileName
onready var ruleset_texture := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/TextureRect
onready var template_title := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/TemplateContainer/HBoxContainer/FileName
onready var template_texture := $ColorRect/VSplitContainer/MarginContainer/VBoxContainer/TemplateContainer/TextureRect


func load_data(tile_data: Dictionary, file_name: String):
	title.text = file_name
	var input_file: String = tile_data["texture"]
	var input_path: String = Const.current_dir + "/" + input_file
	var input_image = Image.new()
	var err: int
	err = input_image.load(input_path)
	if err == OK:
		input_title.text = input_file
		var texture = ImageTexture.new()
		texture.create_from_image(input_image, 0)
		input_texture.texture = texture
	else:
		template_title.text = "NO"
	
	var ruleset_file: String = tile_data["ruleset"]
	var file_path: String = Const.current_dir + "/" + ruleset_file
	var file := File.new()
	if file.open(file_path, File.READ) == OK:
		ruleset_title.text = ruleset_file
#		data.text = file.get_as_text()
	else:
		ruleset_title.text = "NO"


	var template_file: String = tile_data["template"]
	var template_path: String = Const.current_dir + "/" + template_file
	var template_image = Image.new()
	err = template_image.load(template_path)
	if err == OK:
		template_title.text = template_file
		var texture = ImageTexture.new()
		texture.create_from_image(template_image, 0)
		template_texture.texture = texture
	else:
		template_title.text = "NO"
