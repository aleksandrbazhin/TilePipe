extends VBoxContainer

class_name TileMainView

onready var title := $Label
onready var input_title := $MarginContainer/VBoxContainer/InputContainer/HBoxContainer/FileName
onready var input_texture_container := $MarginContainer/VBoxContainer/InputContainer/ScalableTextureContainer
onready var ruleset_filename := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/HBoxContainer/FileName
onready var ruleset_name := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/Name
onready var ruleset_description := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/Description
onready var ruleset_texture := $MarginContainer/VBoxContainer/PanelContainer/MarginContainer/RulesetContainer/ScrollContainer/TextureRect
onready var template_title := $MarginContainer/VBoxContainer/TemplateContainer/HBoxContainer/FileName
onready var template_texture := $MarginContainer/VBoxContainer/TemplateContainer/TextureRect


signal tile_size_changed(size)
#signal file_dialog_started()
#signal file_dialog_ended()


func load_data(tile: TileInTree):
	title.text = tile.tile_file_name
	if tile.texture_path != "":
		input_title.text = tile.texture_path.get_file()
		input_texture_container.set_texture(tile.loaded_texture, tile.input_tile_size)
	if tile.loaded_ruleset.is_loaded:
		ruleset_filename.text = tile.ruleset_path.get_file()
		ruleset_name.text = tile.loaded_ruleset.get_name()
		ruleset_description.text = tile.loaded_ruleset.get_description()
		ruleset_texture.texture = tile.loaded_ruleset.preview_texture
		add_ruleset_highlights(tile.loaded_ruleset)
	if tile.template_path != "":
		template_title.text = tile.template_path.get_file()
		template_texture.texture = tile.loaded_template


func add_ruleset_highlights(ruleset: Ruleset):
	for old_highlight in ruleset_texture.get_children():
		old_highlight.queue_free()
	for i in ruleset.get_tile_parts().size():
		var highlight := preload("res://src/nodes/TileHighlight.tscn").instance()
		ruleset_texture.add_child(highlight)
		highlight.rect_position.x = i * (ruleset.PREVIEW_SIZE_PX + ruleset.PREVIEW_SPACE_PX)
		highlight.set_id(i + 1)


func _on_ScalableTextureContainer_tile_size_changed(size: Vector2):
	emit_signal("tile_size_changed", size)
