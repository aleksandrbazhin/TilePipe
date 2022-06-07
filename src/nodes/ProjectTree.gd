extends Panel

class_name ProjectTree

signal _snapshot_state_changed()

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
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
		var tile: TileInProject = tile_container.get_child(int(settings["selected_tile"]))
		if tile != null:
			tile.set_selected(true)
			tile.select_root()


func on_tile_row_selected(row: TreeItem, tile: TileInProject):
	for other_tile in tile_container.get_children():
		other_tile.deselect_except(row)
		if other_tile.is_selected:
			other_tile.set_selected(false)
	tile.set_selected(true)
	State.set_current_tile(tile, row)
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
	State.current_dir = directory_path
	clear_tree()
	var tiles_found := scan_directory(directory_path)
	if tiles_found.empty():
		no_tiles_found.show()
	else:
		no_tiles_found.hide()
		for tile_fname in tiles_found:
			add_tile_to_tree(directory_path, tile_fname)


func add_tile_to_tree(directory: String, tile_file: String):
	var tile: TileInProject = preload("res://src/nodes/TileInProject.tscn").instance()
	if tile.load_tile(directory, tile_file):
		tile.connect("row_selected", self, "on_tile_row_selected", [tile])
	tile_container.add_child(tile)


func _on_OpenFolderDialog_dir_selected(dir: String):
	if dir + "/" != $OpenFolderDialog.current_path:
		$OpenFolderDialog.current_path = dir + "/"
	load_project_directory(dir)


func _on_DirLoadButton_pressed():
	$OpenFolderDialog.popup_centered()


func hide_file_dialog():
	$OpenFolderDialog.hide()


func _on_OpenFolderDialog_about_to_show():
	State.popup_started($OpenFolderDialog)


func _on_OpenFolderDialog_popup_hide():
	State.popup_ended()


func _on_NewButton_pressed():
	pass # Replace with function body.
