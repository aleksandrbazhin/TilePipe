extends Node


signal tile_selected(tile_node, row_item)
signal tile_cleared()
signal tile_needs_render()
signal popup_started()
signal popup_ended()
signal report_error(message)
# warning-ignore:unused_signal
signal render_progress(progress)

var app_version: String = ProjectSettings.get_setting("application/config/version")
var window_title_base := "TilePipe v.%s" % app_version
var current_window_title := window_title_base
var current_dir := OS.get_executable_path().get_base_dir() + "/" + Const.EXAMPLES_DIR
var current_tile_ref: WeakRef = null
var current_modal_popup: Popup = null


func set_current_tile(tile: TPTile, row: TreeItem = null):
	if current_tile_ref == null or current_tile_ref.get_ref() != tile:
		current_tile_ref = weakref(tile)
	current_window_title = tile.tile_file_name + " - " + window_title_base
	OS.set_window_title(current_window_title)
	if row != null:
		emit_signal("tile_selected", tile, row)
	else:
		emit_signal("tile_cleared")
		tile.select_root()


func get_current_tile() -> TPTile:
	if current_tile_ref == null:
#		report_error("Error: failed to load tile")
		return null
	var tile: TPTile = current_tile_ref.get_ref()
	return tile


func clear_current_tile():
	emit_signal("tile_cleared")
	current_tile_ref = null


func update_tile_param(param_key: int, value, needs_render: bool = true):
	var tile: TPTile = get_current_tile()
	if tile == null:
		return
	if tile.update_param(param_key, value):
		tile.save()
		if needs_render:
			emit_signal("tile_needs_render")


func report_error(message: String):
	emit_signal("report_error", message)	


func popup_started(popup: Popup):
	current_modal_popup = popup
	emit_signal("popup_started")


func popup_ended():
	current_modal_popup = null
	emit_signal("popup_ended")
