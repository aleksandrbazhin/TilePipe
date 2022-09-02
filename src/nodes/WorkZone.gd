extends ColorRect

class_name WorkZone


var loaded_tile_ref: WeakRef
var last_visible_tab

onready var tile_main_view: TileMainView = $VSplitContainer/Control/TileMainView
onready var ruleset_view: RulesetView = $VSplitContainer/Control/RulesetView
onready var template_view: TemplateView = $VSplitContainer/Control/TemplateView
onready var result_view: ResultView = $VSplitContainer/ResultView
onready var renderer: TileRenderer = $TileRenderer


func _ready():
	State.connect("tile_selected", self, "on_tile_selected")
	State.connect("tile_needs_render", self, "render_subtiles")
	renderer.connect("tiles_ready", self, "on_tiles_rendered")
	renderer.connect("report_progress", self, "update_progress")


func unhide_all():
	if is_instance_valid(last_visible_tab):
		last_visible_tab.show()


func hide_all():
	tile_main_view.hide()
	ruleset_view.hide()
	template_view.hide()


func on_tile_selected(tile: TPTile, row: TreeItem):
	hide_all()
	render_subtiles()
	match row:
		tile.tile_row:
			tile_main_view.show()
			tile_main_view.load_data(tile)
			last_visible_tab = tile_main_view
		tile.ruleset_row:
			ruleset_view.show()
			ruleset_view.load_data(tile)
			last_visible_tab = ruleset_view
		tile.template_row:
			template_view.show()
			template_view.load_data(tile)
			last_visible_tab = template_view


func render_subtiles():
	var tile: TPTile = State.get_current_tile()
	if tile == null or tile.loaded_texture == null or tile.loaded_ruleset == null \
			or tile.loaded_template == null:
		result_view.clear()
		return
	var input_image: Image = tile.loaded_texture.get_data()
	renderer.start_render(tile, input_image)
#	State.emit_signal("block")
	update_progress(0)
#	render_progress_overlay.show()



func update_progress(progress: int):
	State.emit_signal("render_progress", progress)


func on_tiles_rendered():
	var tile: TPTile = State.get_current_tile()
	result_view.render_from_tile(tile)
	update_progress(100)

func _on_TileMainView_ruleset_view_called():
	var tile: TPTile = State.get_current_tile()
	tile.select_row(tile.ruleset_row)


func _on_TileMainView_template_view_called():
	var tile: TPTile = State.get_current_tile()
	tile.select_row(tile.template_row)
