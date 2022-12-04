class_name TileMainView
extends VBoxContainer


signal ruleset_view_called()
signal template_view_called()

var current_texture_path := ""
var current_input_tile_size := Vector2.ZERO

onready var ruleset_option := $HBox/VBoxLeft/RulesetContainer/RulesetHeader/RulesetOptionButton
onready var ruleset_texture := $HBox/VBoxLeft/RulesetContainer/ScrollContainer/TextureRect
onready var template_option := $HBox/VBoxLeft/TemplateContainer/TemplateHeader/TemplateOptionButton
onready var template_texture := $HBox/VBoxLeft/TemplateContainer/TextureRect
onready var texture_option := $HBox/VBoxLeft/HeaderContainer/TextureOption
onready var texture_container: ScalableTextureContainer = $HBox/VBoxLeft/ScalableTextureContainer
onready var settings_container: SettingsContainer = $HBox/SettingsContainer


func load_data(tile: TPTile):
	if tile == null:
		return
	current_texture_path = tile.texture_path
	populate_texture_option(current_texture_path)
	current_input_tile_size = tile.input_tile_size
	load_texture(tile.input_texture)
	settings_container.load_data(tile)
	populate_ruleset_option(tile.ruleset_path)
	if tile.ruleset != null and tile.ruleset.is_loaded:
		ruleset_texture.texture = tile.ruleset.preview_texture
		add_ruleset_highlights(tile.ruleset)
	else:
		clear_ruleset()
	populate_template_option(tile.template_path)
	if not tile.template_path.empty():
		template_texture.texture = tile.template
	else:
		clear_template()


func populate_texture_option(texture_path: String):
	Helpers.populate_project_file_option(texture_option, 
		State.current_dir, 
		funcref(Helpers, "scan_for_textures_in_dir"),
		texture_path)


func populate_ruleset_option(ruleset_path: String):
	Helpers.populate_project_file_option(ruleset_option, 
		State.current_dir + Const.RULESET_DIR, 
		funcref(Helpers, "scan_for_rulesets_in_dir"),
		ruleset_path)

	
func populate_template_option(template_path: String):
	Helpers.populate_project_file_option(template_option, 
		State.current_dir + Const.TEMPLATE_DIR, 
		funcref(Helpers, "scan_for_templates_in_dir"),
		template_path)


func _on_AddTextureFileDialog_file_selected(path: String):
	if not Helpers.ensure_directory_exists(State.current_dir, Const.TEXTURE_DIR):
		State.report_error("Error: Creating directory \"/%s/\" error" % Const.TEXTURE_DIR)
		return
	var new_texture_path: String = State.current_dir + Const.TEXTURE_DIR + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_texture_path)
	if error != OK:
		State.report_error("Error: Copy file error number %d." % error)
	current_texture_path = new_texture_path
	populate_texture_option(current_texture_path)
	State.update_tile_param(TPTile.PARAM_TEXTURE, current_texture_path)
	load_texture(State.get_current_tile().input_texture)


func load_texture(texture: Texture):
	texture_container.set_main_texture(texture)


func clear_ruleset():
	ruleset_texture.texture = null
	for old_highlight in ruleset_texture.get_children():
		old_highlight.queue_free()


func clear_template():
	template_texture.texture = null


func clear():
	clear_texture()
	clear_template()
	clear_ruleset()
	settings_container.clear()


func clear_texture():
	texture_option.selected = texture_option.get_item_count() - 1
	texture_container.clear()


func add_ruleset_highlights(ruleset: Ruleset):
	for old_highlight in ruleset_texture.get_children():
		old_highlight.queue_free()
	for i in ruleset.parts.size():
		var highlight := preload("res://src/nodes/PartHighlight.tscn").instance()
		ruleset_texture.add_child(highlight)
		highlight.rect_position.x = i * (ruleset.PREVIEW_SIZE_PX + ruleset.PREVIEW_SPACE_PX)
		highlight.set_id(i + 1, true)
		highlight.connect("focused", self, "on_part_highlight_focused")
		highlight.connect("unfocused", self, "on_part_highlight_unfocused")


func on_part_highlight_focused(part: PartHighlight):
	texture_container.set_part_highlight(part.id, true)


func on_part_highlight_unfocused(part: PartHighlight):
	texture_container.set_part_highlight(part.id, false)


func _on_RulesetButton_pressed():
	emit_signal("ruleset_view_called")


func _on_TemplateButton_pressed():
	emit_signal("template_view_called")


func _on_RulesetOptionButton_item_selected(index):
	var ruleset_path: String = ruleset_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_RULESET, ruleset_path)
	if ruleset_path.empty():
		clear_ruleset()
		return
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	if tile.ruleset == null:
		return
	ruleset_texture.texture = tile.ruleset.preview_texture
	add_ruleset_highlights(tile.ruleset)
	settings_container.populate_frame_control()


func _on_TemplateOptionButton_item_selected(index):
	var template_path: String = template_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_TEMPLATE, template_path, false)
	if template_path.empty():
		clear_template()
		return
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	State.emit_signal("tile_needs_render")
	template_texture.texture = tile.template
#	tile.reload()


func _on_TextureOption_item_selected(index):
	current_texture_path = texture_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_TEXTURE, current_texture_path)
	if current_texture_path.empty():
		clear()
	else:
		var tile: TPTile = State.get_current_tile()
		if tile == null:
			return
		load_texture(tile.input_texture)


func _on_ReloadButton_pressed():
	var tile: TPTile = State.get_current_tile()
	if tile == null:
		return
	tile.reload()


func _on_TextureDialogButton_pressed():
	$AddTextureFileDialog.popup_centered()


func _on_AddTextureFileDialog_about_to_show():
	State.popup_started($AddTextureFileDialog)


func _on_AddTextureFileDialog_popup_hide():
	State.popup_ended()


func _on_ScalableTextureContainer_tile_size_changed(size):
	current_input_tile_size = size
	State.update_tile_param(TPTile.PARAM_INPUT_SIZE, current_input_tile_size)
	settings_container.setup_sliders(current_input_tile_size)
	settings_container.populate_frame_control()
