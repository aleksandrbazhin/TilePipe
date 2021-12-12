extends Control


var generation_data: GenerationData

onready var text_node = $HBoxContainer/PresetContainer/RichTextLabel
onready var image_node = $HBoxContainer/TemplateContainer/TemplateTextureRect


func _ready():
	generation_data = GenerationData.new("res://generation_data/overlay_25_255.json")


func _on_PresetButton_pressed():
	text_node.text = JSON.print(generation_data.data, "\t")


func _on_TemplateButton_pressed():
	image_node.draw_data(generation_data.data)
#	image_node.texture = load(generation_data.get_example_path())
