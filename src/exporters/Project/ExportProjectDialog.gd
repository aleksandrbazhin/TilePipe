class_name ExportProjectDialog
extends WindowDialog

var tile_number := 0
var frame_number := 0
var subtile_number := 0
var render_subtile_count := 0
var total_size := Vector2.ZERO


onready var result_texture := $MarginContainer/VBoxContainer/ProjectResultTextureRect
onready var progress_bar := $ProgressBar

var tile_offsets: Array


func setup(tiles: Array):
	total_size = Vector2.ZERO
	tile_offsets = []
	tile_number = tiles.size()
	frame_number = 0
	subtile_number = 0
	for tile in tiles:
		if not tile.is_able_to_render():
			continue
		frame_number += tile.frames.size()
		if not tile.frames.empty():
			subtile_number += tile.frames[0].get_subtile_count() * tile.frames.size()
		var frame_size = tile.template_size * tile.get_output_tile_size()
		tile_offsets.append(total_size.y)
		total_size = Vector2(
			max(total_size.x, frame_size.x), 
			total_size.y + frame_size.y * tile.frames.size())
	result_texture.reset(total_size)
	update_progress(0)
	render_subtile_count = 0


func on_frame_render(frame_index: int, tile: TPTile, tile_index: int):
	add_tile_frame(tile, frame_index, tile_index)
	if subtile_number != 0:
		render_subtile_count += tile.frames[0].get_subtile_count()
# warning-ignore:integer_division
		var progress: int = 100 * render_subtile_count / subtile_number
		update_progress(progress)


func update_progress(progress: int):
	progress_bar.value = progress
#	State.emit_signal("render_progress", progress)


func add_tile_frame(tile: TPTile, frame_index: int, tile_index: int):
	var frame_size := tile.template_size * tile.get_output_tile_size()
	var frame: TPTileFrame = tile.frames[frame_index]
	frame.merge_result_from_subtiles(tile.template_size, 
		tile.get_output_tile_size(), tile.subtile_spacing)
	var frame_offset_y = tile_offsets[tile_index] + frame_index * frame_size.y
	result_texture.add_texture(frame.result_texture, Vector2(0, frame_offset_y))


func _on_ExportProjectDialog_about_to_show():
	State.popup_started(self)


func _on_ExportProjectDialog_popup_hide():
	State.popup_ended()


func _on_ButtonCancel_pressed():
	hide()


func _on_ButtonOk_pressed():
	hide()
