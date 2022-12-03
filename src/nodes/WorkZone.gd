class_name WorkZone
extends ColorRect


var loaded_tile_ref: WeakRef
var last_visible_tab

var total_frames := 0
var ready_frames := 0

var is_rendering := false
var is_render_scheduled := false

onready var tile_main_view: TileMainView = $VSplitContainer/TopContainer/TileMainView
onready var ruleset_view: RulesetView = $VSplitContainer/TopContainer/RulesetView
onready var template_view: TemplateView = $VSplitContainer/TopContainer/TemplateView
onready var result_view: ResultView = $VSplitContainer/ResultView


func _ready():
	State.connect("tile_cleared", self, "on_tile_cleared")
	State.connect("tile_selected", self, "on_tile_selected")
	State.connect("tile_needs_render", self, "render_subtiles")
	tile_main_view.connect("ruleset_view_called", self, "_on_TileMainView_ruleset_view_called")
	tile_main_view.connect("template_view_called", self, "_on_TileMainView_template_view_called")


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
	result_view.set_export_option(tile.export_type)
	result_view.display_export_path(tile.export_type)


func on_tile_cleared():
	tile_main_view.show()
	tile_main_view.clear()
	result_view.clear()


func render_subtiles():
	var tile: TPTile = State.get_current_tile()
	if tile == null or tile.input_texture == null or tile.ruleset == null \
			or not tile.ruleset.is_loaded or tile.template == null:
		result_view.clear()
		return
	if is_rendering:
		is_render_scheduled = true
		return
	is_rendering = true
	total_frames = tile.frames.size()
	ready_frames = 0
	var frame_index: = 0
	for frame in tile.frames:
		var renderer := TileRenderer.new()
		add_child(renderer)
		renderer.connect("subtiles_ready", self, "on_tile_rendered", [renderer])
		renderer.connect("report_progress", self, "update_progress")
		renderer.start_render(tile, frame_index)
		frame_index += 1 
	update_progress(0)


func update_progress(progress: int):
	State.emit_signal("render_progress", progress)


func on_tile_rendered(frame_index: int, renderer: TileRenderer = null):
	result_view.clear()
	update_progress(100)
	ready_frames += 1
	if total_frames == ready_frames:
		result_view.combine_result_from_tile(State.get_current_tile())
		is_rendering = false
		if is_render_scheduled:
			is_render_scheduled = false
			render_subtiles()
	renderer.queue_free()
	var tile: TPTile = State.get_current_tile()
	if tile != null:
		tile.update_icon()


func _on_TileMainView_ruleset_view_called():
	var tile: TPTile = State.get_current_tile()
	tile.select_row(tile.ruleset_row)


func _on_TileMainView_template_view_called():
	var tile: TPTile = State.get_current_tile()
	tile.select_row(tile.template_row)
