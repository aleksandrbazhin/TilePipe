extends Node

signal tile_selected(tile_node, row_item)
signal tile_updated()
signal popup_started()
signal popup_ended()
signal report_error(message)

var app_version: String = ProjectSettings.get_setting("application/config/version")
var window_title_base := "TilePipe v.%s" % app_version
var current_window_title := window_title_base
var current_dir := OS.get_executable_path().get_base_dir() + "/" + Const.EXAMPLES_DIR
var current_tile_ref: WeakRef = null
var current_modal_popup: Popup = null


func set_current_tile(tile: TileInTree, row: TreeItem):
	if State.current_tile_ref == null or State.current_tile_ref.get_ref() != tile:
		State.current_tile_ref = weakref(tile)
	current_window_title = tile.tile_file_name + " - " + window_title_base
	OS.set_window_title(current_window_title)
	emit_signal("tile_selected", tile, row)


func update_tile_size(size: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	if tile.input_tile_size != size:
		tile.set_input_tile_size(size)
		tile.save()
		emit_signal("tile_updated")


func update_tile_overlap_level(level: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_overlap_level(level)
	tile.save()
	emit_signal("tile_updated")


func update_tile_merge_level(level: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_merge_level(level)
	tile.save()
	emit_signal("tile_updated")


func update_tile_smoothing(smoothing_enabled: bool):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_smoothing(smoothing_enabled)
	tile.save()
	emit_signal("tile_updated")


func update_tile_texture(path: String):
	var tile: TileInTree = current_tile_ref.get_ref()
	if tile.set_texture(path):
		tile.save()
		emit_signal("tile_updated")


func update_tile_ruleset(path: String):
	var tile: TileInTree = current_tile_ref.get_ref()
	if tile.set_ruleset(path):
		tile.save()
		emit_signal("tile_updated")


func update_tile_template(path: String):
	var tile: TileInTree = current_tile_ref.get_ref()
	if tile.set_template(path):
		tile.save()
		emit_signal("tile_updated")


func report_error(message: String):
	emit_signal("report_error", message)	


func popup_started(popup: Popup):
	current_modal_popup = popup
	emit_signal("popup_started")


func popup_ended():
	current_modal_popup = null
	emit_signal("popup_ended")
