extends ColorRect

class_name RulesetView

signal file_dialog_started()
signal file_dialog_ended()
signal report_error(text)

var current_ruleset_path := ""

onready var tile_name := $VBoxContainer/HBoxContainer/TileNameLabel
onready var ruleset_options: OptionButton = $VBoxContainer/HBoxContainer/RulesetFileName
onready var header_data := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/RawHeader
onready var ruleset_name := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Name
onready var description := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Description
onready var parts_texture := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/ScrollContainer/TextureRect
onready var tiles_container := $VBoxContainer/ScrollContainer/VBoxContainer
onready var scroll_container := $VBoxContainer/ScrollContainer


func load_data(tile: TileInTree):
	if tile.ruleset_path != "":
		current_ruleset_path = tile.ruleset_path
		tile_name.text = tile.tile_file_name
		header_data.text = tile.loaded_ruleset.get_raw_header()
		ruleset_name.text = tile.loaded_ruleset.get_name()
		description.text = tile.loaded_ruleset.get_description()
		parts_texture.texture = tile.loaded_ruleset.preview_texture
		populate_ruleset_opions()
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
	$AddRulesetFileDialog.popup_centered()


func populate_ruleset_opions():
	ruleset_options.clear()
	var rulesets_found := get_rulesets_in_project()
	for i in rulesets_found.size():
		if is_file_a_ruleset(rulesets_found[i]):
			ruleset_options.add_item(rulesets_found[i].get_file())
			if rulesets_found[i] == current_ruleset_path:
				ruleset_options.selected = i


func scan_for_rulesets_in_project(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "json":
			files.append(path + "/" + file)
	dir.list_dir_end()
	return files


func get_rulesets_in_project() -> PoolStringArray:
	var rulesets_found := scan_for_rulesets_in_project(Const.current_dir)
	rulesets_found += scan_for_rulesets_in_project(Const.current_dir + "/rulesets")
	return rulesets_found
	
	
func _on_AddRulesetFileDialog_popup_hide():
	emit_signal("file_dialog_ended")


func _on_AddRulesetFileDialog_about_to_show():
	emit_signal("file_dialog_started")


func _on_AddRulesetFileDialog_file_selected(path: String):
	if is_file_a_ruleset(path):
		var dir := Directory.new()
		var ruleset_dir := Const.current_dir + "/rulesets/"
		if not dir.dir_exists(ruleset_dir):
			dir.make_dir(ruleset_dir)
		var error := dir.copy(path, ruleset_dir + path.get_file())
		if error == OK:
			populate_ruleset_opions()
		else:
			emit_signal("report_error", "Error copying file: Copy error number %d." % error)
	else:
		emit_signal("report_error", "Error: Selected file is not a ruleset.")


func is_file_a_ruleset(path: String) -> String:
	var file := File.new()
	file.open(path, File.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed_data = parse_json(json_text)
	return typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("ruleset_name")


func _on_RulesetFileName_item_selected(index):
	pass # Replace with function body.
