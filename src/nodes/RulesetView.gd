extends ColorRect

class_name RulesetView

onready var name_label := $VBoxContainer/CenterContainer/HBoxContainer/RulesetNameLabel
onready var data := $VBoxContainer/TextureRect/ScrollContainer/RulesetData


func load_data(tile: TileInTree):
	if tile.ruleset_path != "":
		name_label.text = tile.ruleset_path.get_file()
		data.text = tile.loaded_ruleset.raw_json
