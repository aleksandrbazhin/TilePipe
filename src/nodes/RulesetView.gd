extends ColorRect

class_name RulesetView

onready var name_label := $VBoxContainer/CenterContainer/HBoxContainer/RulesetNameLabel
onready var data := $VBoxContainer/TextureRect/ScrollContainer/RulesetData


func load_data(tile_data: Dictionary):
	var file_name: String = tile_data["ruleset"]
	var file_path: String = Const.current_dir + "/" + file_name
#	print(file_path)
	var file := File.new()
	if file.open(file_path, File.READ) == OK:
		name_label.text = file_name
		data.text = file.get_as_text()
	else:
		name_label.text = "NO"

