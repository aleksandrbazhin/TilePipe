extends ColorRect

class_name WorkRect

signal file_dialog_started()
signal file_dialog_ended()
signal report_error(text)

var loaded_tile_ref: WeakRef
var last_visible_tab

onready var tile_main_view: TileMainView = $VSplitContainer/Control/TileMainView
onready var input_texture_view: InputTextureView = $VSplitContainer/Control/InputTextureView
onready var ruleset_view: RulesetView = $VSplitContainer/Control/RulesetView
onready var template_view: TemplateView = $VSplitContainer/Control/TemplateView
onready var result_view: ResultView = $VSplitContainer/ResultPreview


func unhide_all():
	if is_instance_valid(last_visible_tab):
		last_visible_tab.show()


func hide_all():
	tile_main_view.hide()
	input_texture_view.hide()
	ruleset_view.hide()
	template_view.hide()


func load_tile_data(tile: TileInTree):
	if loaded_tile_ref == null or loaded_tile_ref.get_ref() != tile:
		loaded_tile_ref = weakref(tile)
		tile_main_view.load_data(tile)
#		input_texture_view.load_data(tile)
#		ruleset_view.load_data(tile)
#		template_view.load_data(tile)


func on_tile_selected(tile: TileInTree, row: TreeItem):
	hide_all()
	load_tile_data(tile)
	match row:
		tile.tile_row:
			tile_main_view.show()
			last_visible_tab = tile_main_view
		tile.texture_row:
			input_texture_view.show()
			input_texture_view.load_data(tile)
			last_visible_tab = input_texture_view
		tile.ruleset_row:
			ruleset_view.show()
			ruleset_view.load_data(tile)
			last_visible_tab = ruleset_view
		tile.template_row:
			template_view.show()
			template_view.load_data(tile)
			last_visible_tab = template_view


func _on_RulesetView_file_dialog_started():
	emit_signal("file_dialog_started")


func _on_RulesetView_file_dialog_ended():
	emit_signal("file_dialog_ended")


func _on_TileMainView_file_dialog_started():
	emit_signal("file_dialog_started")


func _on_TileMainView_file_dialog_ended():
	emit_signal("file_dialog_ended")


func _on_TemplateView_file_dialog_started():
	emit_signal("file_dialog_started")


func _on_TemplateView_file_dialog_ended():
	emit_signal("file_dialog_ended")


func _on_InputTextureView_file_dialog_started():
	emit_signal("file_dialog_started")


func _on_InputTextureView_file_dialog_ended():
	emit_signal("file_dialog_ended")


func _on_RulesetView_tile_ruleset_changed(path: String):
	var tile: TileInTree = loaded_tile_ref.get_ref()
	tile.set_ruleset(path)
	tile.save()
	ruleset_view.load_data(tile)


func _on_TemplateView_tile_template_changed(path: String):
	var tile: TileInTree = loaded_tile_ref.get_ref()
	tile.set_template(path)
	tile.save()
	template_view.load_data(tile)


func _on_InputTextureView_tile_texture_changed(path: String):
	var tile: TileInTree = loaded_tile_ref.get_ref()
	tile.set_texture(path)
	tile.save()
	input_texture_view.load_data(tile)


func _on_InputTextureView_report_error(text: String):
	emit_signal("report_error", text)


func _on_RulesetView_report_error(text: String):
	emit_signal("report_error", text)


func _on_TemplateView_report_error(text: String):
	emit_signal("report_error", text)


func _on_TileMainView_tile_size_changed(size: Vector2):
	var tile: TileInTree = loaded_tile_ref.get_ref()
	tile.set_input_tile_size(size)
	tile.save()
