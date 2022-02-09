extends ColorRect

class_name RulesetView

onready var name_label := $VBoxContainer/CenterContainer/HBoxContainer/RulesetNameLabel
onready var data := $VBoxContainer/ScrollContainer/HSplitContainer/MarginContainer/RulesetData
onready var ruleset_name := $VBoxContainer/ScrollContainer/HSplitContainer/MarginContainer2/VBoxContainer/Name
onready var description := $VBoxContainer/ScrollContainer/HSplitContainer/MarginContainer2/VBoxContainer/Description
onready var parts_texture := $VBoxContainer/ScrollContainer/HSplitContainer/MarginContainer2/VBoxContainer/ScrollContainer/TextureRect
onready var tiles_container := $VBoxContainer/ScrollContainer/HSplitContainer/MarginContainer2/VBoxContainer/VBoxContainer
onready var scroll_container := $VBoxContainer/ScrollContainer

func load_data(tile: TileInTree):
	if tile.ruleset_path != "":
		name_label.text = tile.ruleset_path.get_file()
		data.text = tile.loaded_ruleset.raw_json
		ruleset_name.text = tile.loaded_ruleset.get_name()
		description.text = tile.loaded_ruleset.get_description()
		parts_texture.texture = tile.loaded_ruleset.preview_texture
		add_ruleset_highlights(tile.loaded_ruleset)
		add_tiles(tile.loaded_ruleset)
	

func add_ruleset_highlights(ruleset: Ruleset):
#	var index := 0
	for old_highlight in parts_texture.get_children():
		old_highlight.queue_free()
	for i in ruleset.get_tile_parts().size():
		var highlight := preload("res://src/nodes/TileHighlight.tscn").instance()
		parts_texture.add_child(highlight)
		highlight.rect_position.x = i * (ruleset.PREVIEW_SIZE_PX + ruleset.PREVIEW_SPACE_PX)
		highlight.set_id(i + 1)


func add_tiles(ruleset: Ruleset):
#	ruleset.preview_texture

	for old_tile in tiles_container.get_children():
		old_tile.queue_free()
	for tile_index in ruleset.get_tiles().size():
		var tile_view: TileInRuleset = preload("res://src/nodes/TileInRuleset.tscn").instance()
		tile_view.setup(ruleset, tile_index)
		tiles_container.add_child(tile_view)
