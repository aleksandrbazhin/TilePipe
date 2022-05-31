extends VBoxContainer

class_name TileMainView


signal tile_size_changed(size)
signal input_texture_view_called()
signal ruleset_view_called()
signal template_view_called()
#signal file_dialog_started()
#signal file_dialog_ended()

onready var title := $Label
onready var input_texture := $InputTextureView
#onready var input_title := $MarginContainer/VBoxContainer/InputContainer/HBoxContainer/TextureButton
#onready var input_texture_container := $MarginContainer/VBoxContainer/InputContainer/ScalableTextureContainer
onready var ruleset_filename := $RulesetContainer/RulesetButton
onready var ruleset_button := $RulesetContainer/RulesetButton
#onready var ruleset_description := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/Description
onready var ruleset_texture := $RulesetContainer/ScrollContainer/TextureRect
onready var template_title := $TemplateContainer/TemplateButton
onready var template_texture := $TemplateContainer/TextureRect


func load_data(tile: TileInTree):
	title.text = tile.tile_file_name
	if tile.texture_path != "":
		input_texture.load_data(tile)
#		input_title.text = tile.texture_path.get_file()
#		input_texture_container.set_texture(tile.loaded_texture, tile.input_tile_size)
	if tile.loaded_ruleset.is_loaded:
		ruleset_filename.text = tile.ruleset_path.get_file()
		ruleset_button.text = tile.loaded_ruleset.get_name()
#		ruleset_description.text = tile.loaded_ruleset.get_description()
		ruleset_texture.texture = tile.loaded_ruleset.preview_texture
		add_ruleset_highlights(tile.loaded_ruleset)
	if tile.template_path != "":
		template_title.text = tile.template_path.get_file()
		template_texture.texture = tile.loaded_template


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


func _on_ScalableTextureContainer_tile_size_changed(size: Vector2):
	emit_signal("tile_size_changed", size)


func _on_TextureButton_pressed():
	emit_signal("input_texture_view_called")


func _on_RulesetButton_pressed():
	emit_signal("ruleset_view_called")


func _on_TemplateButton_pressed():
	emit_signal("template_view_called")
