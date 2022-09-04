extends ColorRect

class_name RulesetView


const TILE_UPDATE_CHUNK := 8

var part_highlight_scene := preload("res://src/nodes/PartHighlight.tscn")
var current_ruleset_path := ""

onready var tile_name := $VBoxContainer/HBoxContainer/TileNameLabel
onready var ruleset_option: OptionButton = $VBoxContainer/HBoxContainer/RulesetFileName
onready var header_data := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/RawHeader
onready var ruleset_name := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Name
onready var description := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/Description
onready var parts_texture := $VBoxContainer/HeaderContainer/MarginContainer/Hbox/VBoxContainer/ScrollContainer/TextureRect
onready var tiles_container := $VBoxContainer/ScrollContainer/VBoxContainer
onready var scroll_container := $VBoxContainer/ScrollContainer


func load_data(tile: TPTile):
	if tile == null:
		return
	tile_name.text = tile.tile_file_name
	current_ruleset_path = tile.ruleset_path
	populate_ruleset_option()
	if tile.ruleset_path.empty():
		clear()
		return
	header_data.text = tile.loaded_ruleset.get_raw_header()
	ruleset_name.text = tile.loaded_ruleset.get_name()
	description.text = tile.loaded_ruleset.get_description()
	parts_texture.texture = tile.loaded_ruleset.preview_texture
	add_ruleset_highlights(tile.loaded_ruleset)
	add_tiles(tile.loaded_ruleset)
	if tile.loaded_ruleset.last_error != -1:
		State.report_error("Error loading tile:\n" + tile.loaded_ruleset.last_error_message)


func add_ruleset_highlights(ruleset: Ruleset):
	clear_highlight()
	for i in ruleset.get_parts().size():
		var highlight: PartHighlight = part_highlight_scene.instance()
		parts_texture.add_child(highlight)
		highlight.rect_position.x = i * (ruleset.PREVIEW_SIZE_PX + ruleset.PREVIEW_SPACE_PX)
		highlight.set_id(i + 1)


func clear():
	header_data.text = ""
	ruleset_name.text = ""
	description.text = ""
	parts_texture.texture = null
	clear_highlight()
	clear_tiles()


func clear_highlight():
	for old_highlight in parts_texture.get_children():
		old_highlight.queue_free()


func clear_tiles():
	for old_tile in tiles_container.get_children():
		old_tile.queue_free()


func switched_to_another_ruleset(old_ruleset_path: String) -> bool:
	return old_ruleset_path != current_ruleset_path


func add_tiles(ruleset: Ruleset):
	clear_tiles()
	var working_ruleset_path := current_ruleset_path
	for tile_index in ruleset.get_subtiles().size():
		if switched_to_another_ruleset(working_ruleset_path):
			break
		var tile_view: RuleInRuleset = preload("res://src/nodes/RuleInRuleset.tscn").instance()
		tile_view.setup(ruleset, tile_index)
		tiles_container.add_child(tile_view)
		if tile_index % TILE_UPDATE_CHUNK == 0:
			yield(get_tree(), "idle_frame")


func _on_RulesetDialogButton_pressed():
	$AddRulesetFileDialog.popup_centered()


func _on_AddRulesetFileDialog_about_to_show():
	State.popup_started($AddRulesetFileDialog)


func _on_AddRulesetFileDialog_popup_hide():
	State.popup_ended()


func _on_AddRulesetFileDialog_file_selected(path: String):
	if not Helpers.is_file_a_ruleset(path):
		State.report_error("Error: Selected file is not a ruleset.")
		return
	if not Helpers.ensure_directory_exists(State.current_dir, Const.RULESET_DIR):
		State.report_error("Error: Creating directory \"/%s/\" error" % Const.RULESET_DIR)
		return
	var new_ruleset_path := State.current_dir + "/" + Const.RULESET_DIR + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_ruleset_path)
	if error != OK:
		State.report_error("Error: Copy file error number %d." % error)
		return
	current_ruleset_path = new_ruleset_path
	populate_ruleset_option()
	State.update_tile_param(TPTile.PARAM_RULESET, current_ruleset_path)
	load_data(State.current_tile_ref.get_ref())


func populate_ruleset_option():
	var search_path: String = State.current_dir + "/" + Const.RULESET_DIR
	var scan_func: FuncRef = funcref(Helpers, "scan_for_rulesets_in_dir")
	Helpers.populate_project_file_option(ruleset_option, search_path, 
		scan_func, current_ruleset_path)


func _on_RulesetFileName_item_selected(index: int):
	current_ruleset_path = ruleset_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_RULESET, current_ruleset_path)
	if current_ruleset_path.empty():
		clear()
		return
	load_data(State.current_tile_ref.get_ref())
