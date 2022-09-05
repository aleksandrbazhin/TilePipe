class_name ProjectTree
extends Panel


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
		var tile: TPTile = tile_container.get_child(int(settings["selected_tile"]))
		if tile != null:
			tile.set_selected(true)
			tile.select_root()


func on_tile_row_selected(row: TreeItem, tile: TPTile):
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
		tiles_found.sort()
		for tile_fname in tiles_found:
			add_tile_to_tree(directory_path, tile_fname)


func add_tile_to_tree(directory: String, tile_file: String, is_new: bool = false):
	var tile: TPTile = preload("res://src/nodes/TPTile.tscn").instance()
	if tile.load_tile(directory, tile_file, is_new):
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
	$NewTileDialog/CenterContainer/LineEdit.clear()
	$NewTileDialog.popup_centered()


func _on_NewTileDialog_confirmed():
	var new_name: String = $NewTileDialog/CenterContainer/LineEdit.text
	if new_name.empty():
		State.report_error("Error: empty tile name")
		return
	var tiles_found := scan_directory(State.current_dir)
	new_name += "." + Const.TILE_EXTENXSION
	if new_name in tiles_found:
		State.report_error("Error: tile \"%s\" already exists" % new_name)
		return
	add_tile_to_tree(State.current_dir, new_name, true)


#func _unhandled_input(event: InputEvent):
#	if event is InputEventKey and event.pressed:
#		match event.scancode:
#			KEY_UP:
#				get_tree().set_input_as_handled()
#			KEY_DOWN:
#				get_tree().set_input_as_handled()
