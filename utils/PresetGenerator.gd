extends Control


var generation_data: GenerationData

onready var text_node = $HBoxContainer/PresetContainer/RichTextLabel
onready var render_node: ViewportContainer = $HBoxContainer/TemplateContainer/ScrollContainer/ViewportContainer
#onready var image_node: TextureRect = render_node.get_node("TemplateTextureRect")


func _ready():
	generation_data = GenerationData.new("res://generation_data/overlay_25_255.json")


func _on_PresetButton_pressed():
	text_node.text = JSON.print(generation_data.data, "\t")


func _on_TemplateButton_pressed():
	render_node.draw_data(generation_data.data)
#	image_node.texture = load(generation_data.get_example_path())


func _on_SaveButton_pressed():
	$FileDialog.popup_centered()
	

func _on_FileDialog_file_selected(path):
	var image: Image = render_node.get_texture().get_data()
	image.flip_y()
	image.save_png(path)
