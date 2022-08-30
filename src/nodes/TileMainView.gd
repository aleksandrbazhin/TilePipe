extends VBoxContainer

class_name TileMainView


signal ruleset_view_called()
signal template_view_called()

onready var input_texture := $InputTextureView
onready var ruleset_option := $RulesetContainer/RulesetOptionButton
onready var ruleset_texture := $RulesetContainer/ScrollContainer/TextureRect
onready var template_option := $TemplateContainer/TemplateOptionButton
onready var template_texture := $TemplateContainer/TextureRect
onready var export_type_option := $ExportContainer/ExportOptionButton
onready var export_path_edit := $ExportContainer/ExportPathLineEdit


func load_data(tile: TileInProject):
	if tile == null:
		return
	if tile.texture_path != "":
		input_texture.load_data(tile)
	if tile.loaded_ruleset.is_loaded:
		ruleset_option.text = tile.loaded_ruleset.get_name()
		ruleset_texture.texture = tile.loaded_ruleset.preview_texture
		add_ruleset_highlights(tile.loaded_ruleset)
		Helpers.populate_project_file_option(ruleset_option, 
			State.current_dir + "/" + Const.RULESET_DIR, 
			funcref(Helpers, "scan_for_rulesets_in_dir"),
			tile.ruleset_path)
	if tile.template_path != "":
		template_option.text = tile.template_path.get_file()
		template_texture.texture = tile.loaded_template
		Helpers.populate_project_file_option(template_option, 
			State.current_dir + "/" + Const.TEMPLATE_DIR, 
			 funcref(Helpers, "scan_for_templates_in_dir"),
			 tile.template_path)
	if tile.export_type != Const.EXPORT_TYPE_UKNOWN:
		export_type_option.select(tile.export_type)
	display_export_path(tile.export_type)


func add_ruleset_highlights(ruleset: Ruleset):
	for old_highlight in ruleset_texture.get_children():
		old_highlight.queue_free()
	for i in ruleset.get_parts().size():
		var highlight := preload("res://src/nodes/PartHighlight.tscn").instance()
		ruleset_texture.add_child(highlight)
		highlight.rect_position.x = i * (ruleset.PREVIEW_SIZE_PX + ruleset.PREVIEW_SPACE_PX)
		highlight.set_id(i + 1)
		highlight.connect("focused", self, "on_part_highlight_focused")
		highlight.connect("unfocused", self, "on_part_highlight_unfocused")


func on_part_highlight_focused(part: PartHighlight):
	input_texture.change_part_highlight(part.id, true)


func on_part_highlight_unfocused(part: PartHighlight):
	input_texture.change_part_highlight(part.id, false)


func _on_RulesetButton_pressed():
	emit_signal("ruleset_view_called")


func _on_TemplateButton_pressed():
	emit_signal("template_view_called")


func _on_RulesetOptionButton_item_selected(index):
	State.update_tile_param(TileInProject.PARAM_RULESET, 
		ruleset_option.get_item_metadata(index))
	var tile: TileInProject = State.get_current_tile()
	if tile == null:
		return
	ruleset_texture.texture = tile.loaded_ruleset.preview_texture
	add_ruleset_highlights(tile.loaded_ruleset)


func _on_TemplateOptionButton_item_selected(index):
	State.update_tile_param(TileInProject.PARAM_TEMPLATE, 
		template_option.get_item_metadata(index))
	var tile: TileInProject = State.get_current_tile()
	if tile == null:
		return
	template_texture.texture = tile.loaded_template


func _on_ExportButton_pressed():
	var tile: TileInProject = State.get_current_tile()
	if tile == null:
		return
	if tile.output_texture == null:
		State.report_error("Error: No generated texture")
		return
	match export_type_option.selected:
		Const.EXPORT_TYPES.TEXTURE:
			var dialog := $TextureFileDialog
			dialog.current_path = State.get_current_tile().export_png_path
			dialog.popup_centered()
		Const.EXPORT_TYPES.GODOT3:
			var dialog: GodotExporter = $Godot3ExportDialog
			dialog.start_export_dialog(State.get_current_tile())


func display_export_path(export_type: int):
	var tile: TileInProject = State.get_current_tile()
	if tile == null:
		return
	match export_type:
		Const.EXPORT_TYPES.TEXTURE:
			export_path_edit.text = tile.export_png_path
		Const.EXPORT_TYPES.GODOT3:
			export_path_edit.text = tile.export_godot3_resource_path
			export_path_edit.text += ": " + tile.export_godot3_tile_name
		_:
			export_path_edit.text = ""


func _on_ExportOptionButton_item_selected(index):
	display_export_path(index)
	State.update_tile_param(TileInProject.PARAM_EXPORT_TYPE, index)


func _on_TextureFileDialog_file_selected(path):
	var tile: TileInProject = State.get_current_tile()
	if tile == null:
		return
	var current_texture_image := tile.output_texture
	current_texture_image.get_data().save_png(path)
	State.update_tile_param(TileInProject.PARAM_EXPORT_PNG_PATH, path)


func _on_Godot3ExportDialog_popup_hide():
	display_export_path(Const.EXPORT_TYPES.GODOT3)
