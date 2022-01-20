extends ColorRect

class_name TemplateView

onready var texture_rect := $VBoxContainer/TextureRect
onready var name_label := $VBoxContainer/CenterContainer/HBoxContainer/TemplateNameLabel


func load_data(tile_data: Dictionary):
	var template_file: String = tile_data["template"]
	var template_path: String = Const.current_dir + "/" + template_file
	var template_image = Image.new()
	var err = template_image.load(template_path)
	if err == OK:
		name_label.text = template_file
		var texture = ImageTexture.new()
		texture.create_from_image(template_image, 0)
		texture_rect.texture = texture
	else:
		name_label.text = "NO"
