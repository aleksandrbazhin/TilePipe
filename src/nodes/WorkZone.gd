extends ColorRect

class_name WorkZone

#signal file_dialog_started()
#signal file_dialog_ended()
#signal report_error(text)

var loaded_tile_ref: WeakRef
var last_visible_tab

onready var tile_main_view: TileMainView = $VSplitContainer/Control/TileMainView
onready var ruleset_view: RulesetView = $VSplitContainer/Control/RulesetView
onready var template_view: TemplateView = $VSplitContainer/Control/TemplateView
onready var result_view: ResultView = $VSplitContainer/ResultView
onready var renderer: TileRenderer = $TileRenderer


func unhide_all():
	if is_instance_valid(last_visible_tab):
		last_visible_tab.show()


func hide_all():
	tile_main_view.hide()
	ruleset_view.hide()
	template_view.hide()


func on_tile_selected(tile: TileInTree, row: TreeItem):
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


func _on_RulesetView_tile_ruleset_changed(path: String):
	var tile: TileInTree = State.current_tile_ref.get_ref()
	tile.set_ruleset(path)
	tile.save()
	ruleset_view.load_data(tile)
	render_subtiles()


func _on_TemplateView_tile_template_changed(path: String):
	var tile: TileInTree = State.current_tile_ref.get_ref()
	tile.set_template(path)
	tile.save()
	template_view.load_data(tile)
	render_subtiles()

#
#func _on_InputTextureView_tile_texture_changed(path: String):
#	var tile: TileInTree = State.current_tile_ref.get_ref()
#	tile.set_texture(path)
#	tile.save()
#	tile_main_view.input_texture.load_data(tile)
#	render_subtiles()



func render_subtiles():
#	var tile: TileInTree = loaded_tile_ref.get_ref()
	var tile: TileInTree = State.current_tile_ref.get_ref()
	var input_image: Image = tile.loaded_texture.get_data()
#	var parts_in_ruleset := int(tile.loaded_ruleset.get_parts().size())
#	var min_input_tiles := Vector2(, 1)
#	var old_style_input_tile_size: int = int(input_image.get_size().x / min_input_tiles.x)
#	var input_tile_size := Vector2(old_style_input_tile_size, old_style_input_tile_size)
#	var old_style_ouput_tile_size := get_output_tile_size()
#	var output_tile_size := Vector2(old_style_ouput_tile_size, old_style_ouput_tile_size)
#	var input_tile_size := tile.input_tile_size
#	var output_tile_size := Vector2(64, 64)
#	var merge_rate: float = overlay_merge_rate_slider.value
#	var overlap_rate: float = overlay_overlap_slider.value
#
#	if rand_seed_check.pressed:
#		var random_seed_int: int = int(rand_seed_value.text)
#		var random_seed = rand_seed(random_seed_int)
#		rng.seed = random_seed[1]
#
#	renderer.start_render(tile.loaded_ruleset, input_tile_size, output_tile_size,
#		input_image, tile.result_subtiles_by_bitmask, tile.smoothing,
#		tile.merge_level.x, tile.overlap_level.x)
	renderer.start_render(tile, input_image)
	if not renderer.is_connected("tiles_ready", self, "on_tiles_rendered"):
		renderer.connect("tiles_ready", self, "on_tiles_rendered")
#		renderer.connect("report_progress", self, "update_progress")
#	update_progress(0)
#	render_progress_overlay.show()



#func update_progress(progress: int):
#	render_progressbar.value = progress


func on_tiles_rendered():
#	update_progress(100)
	if renderer.is_connected("tiles_ready", self, "on_tiles_rendered"):
		renderer.disconnect("tiles_ready", self, "on_tiles_rendered")
#		renderer.disconnect("report_progress", self, "update_progress")
#	rendered_tiles = renderer.tiles
#	var tile: TileInTree = loaded_tile_ref.get_ref()
#	emit_signal("input_image_processed")
	var tile: TileInTree = State.current_tile_ref.get_ref()
	result_view.render_from_tile(tile)


func _on_TileMainView_ruleset_view_called():
	var tile: TileInTree = State.current_tile_ref.get_ref()
	tile.select_row(tile.ruleset_row)


func _on_TileMainView_template_view_called():
	var tile: TileInTree = State.current_tile_ref.get_ref()
	tile.select_row(tile.template_row)


