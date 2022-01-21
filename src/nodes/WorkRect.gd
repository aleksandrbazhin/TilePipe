extends ColorRect

class_name WorkRect

var loaded_tile_ref: WeakRef
var last_visible_tab

onready var tile_main_view: TileMainView = $TileMainView
onready var input_texture_view: InputTextureView = $InputTextureView
onready var ruleset_view := $RulesetView
onready var template_view: TemplateView = $TemplateView


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
		tile_main_view.load_data(tile.tile_data, tile.tile_file_name)
		input_texture_view.load_data(tile.tile_data)
		ruleset_view.load_data(tile.tile_data)
		template_view.load_data(tile.tile_data)


func on_tile_selected(tile: TileInTree, row: TreeItem):
	hide_all()
	load_tile_data(tile)
	match row:
		tile.tile_row:
			tile_main_view.show()
			last_visible_tab = tile_main_view
		tile.texture_row:
			input_texture_view.show()
			last_visible_tab = input_texture_view
		tile.ruleset_row:
			ruleset_view.show()
			last_visible_tab = ruleset_view
		tile.template_row:
			template_view.show()
			last_visible_tab = template_view
