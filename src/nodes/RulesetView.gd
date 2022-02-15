extends ColorRect

class_name RulesetView

#var current_ruleset

onready var tile_name := $VBoxContainer/HBoxContainer/TileNameLabel
onready var ruleset_options: OptionButton = $VBoxContainer/HBoxContainer/RulesetFileName
onready var header_data := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/RawHeader
onready var ruleset_name := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Name
onready var description := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Description
onready var parts_texture := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/ScrollContainer/TextureRect
onready var tiles_container := $VBoxContainer/ScrollContainer/VBoxContainer
onready var scroll_container := $VBoxContainer/ScrollContainer
onready var ruleset_manager: RulesetMananger = $RulesetManager

func load_data(tile: TileInTree):
	if tile.ruleset_path != "":
		
		populate_ruleset_opions(tile)
#		for 
#		ruleset_file.text = tile.ruleset_path.get_file()
		tile_name.text = tile.tile_file_name
		header_data.text = tile.loaded_ruleset.get_raw_header()
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


func _on_RulesetDialogButton_pressed():
	ruleset_manager.popup_centered()


func populate_ruleset_opions(tile: TileInTree):
	ruleset_options.clear()
	var rulesets_found := ruleset_manager.get_rulesets_in_project()
	for i in rulesets_found.size():
		var file := File.new()
		file.open(rulesets_found[i], File.READ)
		var file_text := file.get_as_text()
		file.close()
		var parsed_data = parse_json(file_text)
		if typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("ruleset_name"):
			ruleset_options.add_item(rulesets_found[i].get_file())
			if rulesets_found[i] == tile.ruleset_path:
				ruleset_options.selected = i



	
	
	
