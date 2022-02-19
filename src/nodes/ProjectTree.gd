extends Panel

class_name ProjectTree

signal file_dialog_started()
signal file_dialog_ended()
signal tile_selected(tile_node, row_item)
signal _snapshot_state_changed()
signal report_error(text)

var is_file_dialog_active := false

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
onready var open_project_dialog := $OpenFolderDialog
onready var no_tiles_found := $NoTilesFound


func _take_snapshot() -> Dictionary:
	var settings := {"selected_tile": 0}
	var index := 0
	for tile in tile_container.get_children():
		if tile.is_selected:
			settings["selected_tile"] = index
			break
		index += 1
	return settings


func _apply_snapshot(settings: Dictionary):
	if tile_container.get_child_count() > 0:
		var tile: TileInTree = tile_container.get_child(int(settings["selected_tile"]))
		if tile != null:
			tile.set_selected(true)
			tile.select_root()


func on_tile_row_selected(row: TreeItem, tile: TileInTree):
	for other_tile in tile_container.get_children():
		other_tile.deselect_except(row)
		if other_tile.is_selected:
			other_tile.set_selected(false)
	tile.set_selected(true)
	emit_signal("tile_selected", tile, row)
	emit_signal("_snapshot_state_changed")


func clear_tree():
	for tile in tile_container.get_children():
		tile.queue_free()


func scan_directory(path: String) -> Array:
	var files := []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == Const.TILE_EXTENXSION:
			files.append(file)
	dir.list_dir_end()
	return files


func load_project_directory(directory_path: String):
	dir_edit.text = directory_path
	Const.current_dir = directory_path
	clear_tree()
	var tiles_found := scan_directory(directory_path)
	if tiles_found.empty():
		no_tiles_found.show()
	else:
		no_tiles_found.hide()
		for tile_fname in tiles_found:
			add_tile_to_tree(directory_path, tile_fname)


func on_error_reported(text: String):
	emit_signal("report_error", text)


func add_tile_to_tree(directory: String, tile_file: String):
	var tile: TileInTree = preload("res://src/nodes/TileInTree.tscn").instance()
	tile.connect("report_error", self, "on_error_reported")
	if tile.load_tile(directory, tile_file):
		tile.connect("row_selected", self, "on_tile_row_selected", [tile])
		tile_container.add_child(tile)
#	else:
#		#TODO: emit signal
#		on_error_reported("Tile loading error!")
#		print()


func _on_OpenFolderDialog_dir_selected(dir: String):
	if dir + "/" != open_project_dialog.current_path:
		open_project_dialog.current_path = dir + "/"
	load_project_directory(dir)


func _on_DirLoadButton_pressed():
	open_project_dialog.popup_centered()


func hide_file_dialog():
	open_project_dialog.hide()


func _on_OpenFolderDialog_popup_hide():
	is_file_dialog_active = false
	emit_signal("file_dialog_ended")


func _on_OpenFolderDialog_about_to_show():
	is_file_dialog_active = true
	emit_signal("file_dialog_started")


func _on_NewButton_pressed():
	pass # Replace with function body.
