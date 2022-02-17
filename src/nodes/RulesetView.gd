extends ColorRect

class_name RulesetView

const TILE_UPDATE_CHUNK := 8

signal file_dialog_started()
signal file_dialog_ended()
signal report_error(text)
signal tile_ruleset_changed(path)

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
		if tile_index % TILE_UPDATE_CHUNK == 0:
			yield(get_tree(), "idle_frame")


func _on_RulesetDialogButton_pressed():
	$AddRulesetFileDialog.popup_centered()


func populate_ruleset_opions():
	ruleset_options.clear()
	var rulesets_found := get_rulesets_in_project()
	var index := 0
	for ruleset_path in rulesets_found:
		if is_file_a_ruleset(ruleset_path):
			ruleset_options.add_item(ruleset_path.get_file())
			ruleset_options.set_item_metadata(index, ruleset_path)
			if ruleset_path == current_ruleset_path:
				ruleset_options.selected = index
			index += 1


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
		if not Helpers.ensure_directory_exists(Const.current_dir, Const.RULESET_DIR):
			emit_signal("report_error", "Error: Creating directory \"/rulesets/\" error")
			return
		var new_ruleset_path := Const.current_dir + "/" + Const.RULESET_DIR + "/" + path.get_file()
		var dir := Directory.new()
		var error := dir.copy(path, new_ruleset_path)
		if error == OK:
			current_ruleset_path = new_ruleset_path
			populate_ruleset_opions()
		else:
			emit_signal("report_error", "Error: Copy file error number %d." % error)
	else:
		emit_signal("report_error", "Error: Selected file is not a ruleset.")


func is_file_a_ruleset(path: String) -> String:
	var file := File.new()
	file.open(path, File.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed_data = parse_json(json_text)
	return typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("ruleset_name")


func _on_RulesetFileName_item_selected(index: int):
	current_ruleset_path = ruleset_options.get_item_metadata(index)
	emit_signal("tile_ruleset_changed", current_ruleset_path)
