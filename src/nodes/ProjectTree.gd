class_name ProjectTree
extends Panel


signal _snapshot_state_changed()

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
onready var no_tiles_found := $NoTilesFound
onready var new_tile_dialog := $NewTileDialog
onready var new_tile_lineedit := $NewTileDialog/CenterContainer/LineEdit
onready var open_dialog := $OpenFolderDialog


func _take_snapshot() -> Dictionary:
	var settings := {"selected_tile": 0}
	for tile in tile_container.get_children():
		if tile.is_selected:
			settings["selected_tile"] = tile.tile_file_name
			break
	return settings


func _apply_snapshot(settings: Dictionary):
	if tile_container.get_child_count() > 0:
		for index in tile_container.get_child_count():
			var tile: TPTile = tile_container.get_child(index)
			if tile.tile_file_name == settings["selected_tile"]:
				tile.set_selected(true)
				tile.select_root()
				break


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
		State.clear_current_tile()
	else:
		no_tiles_found.hide()
		tiles_found.sort()
		var first_tile: TPTile = null
		for tile_fname in tiles_found:
			var tile := add_tile_to_tree(directory_path, tile_fname)
			if first_tile == null:
				first_tile = tile
		State.set_current_tile(first_tile)


func add_tile_to_tree(directory: String, tile_file: String, is_new: bool = false) -> TPTile:
	var tile: TPTile = preload("res://src/nodes/TPTile.tscn").instance()
	if tile.load_tile(directory, tile_file, is_new):
		tile.connect("row_selected", self, "on_tile_row_selected", [tile])
	tile_container.add_child(tile)
	
## This is the correct way (to have tile sorted), but there seems to be 
## difference in add_child() and add_child_below_node() (possibly, a bug)
#	if not is_new or tile_container.get_child_count() == 0:
#		tile_container.add_child(tile)
#	else:
#		var insert_below_tile: TPTile = tile_container.get_child(0)
#		for t in tile_container.get_children():
#			if tile_file < t.tile_file_name:
#				insert_below_tile = t
#		tile.owner = tile_container
#		tile_container.add_child_below_node(tile, insert_below_tile)
	return tile


func _on_OpenFolderDialog_dir_selected(dir: String):
	if dir + "/" != open_dialog.current_path:
		open_dialog.current_path = dir + "/"
	load_project_directory(dir)


func _on_DirLoadButton_pressed():
	open_dialog.popup_centered()


func hide_file_dialog():
	open_dialog.hide()


func _on_OpenFolderDialog_about_to_show():
	State.popup_started(open_dialog)


func _on_OpenFolderDialog_popup_hide():
	State.popup_ended()


func _on_NewButton_pressed():
	new_tile_lineedit.clear()
	new_tile_dialog.popup_centered()
	new_tile_lineedit.grab_focus()


func _on_NewTileDialog_confirmed():
	var new_name: String = new_tile_lineedit.text
	if new_name.empty():
		State.report_error("Error: empty tile name")
		return
	var tiles_found := scan_directory(State.current_dir)
	new_name += "." + Const.TILE_EXTENXSION
	if new_name in tiles_found:
		State.report_error("Error: tile \"%s\" already exists" % new_name)
		return
	no_tiles_found.hide()
	var new_tile := add_tile_to_tree(State.current_dir, new_name, true)
	State.set_current_tile(new_tile)
	new_tile.save()


func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if new_tile_dialog.visible:
			get_tree().set_input_as_handled()
			new_tile_dialog.hide()
#		match event.scancode:
#			KEY_UP:
#				get_tree().set_input_as_handled()
#			KEY_DOWN:
#				get_tree().set_input_as_handled()


func _on_LineEdit_text_entered(_new_text):
	new_tile_dialog.hide()
	new_tile_dialog.emit_signal("confirmed")
