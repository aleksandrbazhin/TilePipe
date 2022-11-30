class_name ProjectTree
extends Panel


signal _snapshot_state_changed()

const NO_TILE := "_no_tile_means_we_select_first_"

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
onready var no_tiles_found := $NoTilesFound
onready var new_tile_dialog := $NewTileDialog
onready var new_tile_lineedit := $NewTileDialog/CenterContainer/LineEdit
onready var open_dialog := $OpenFolderDialog


func _take_snapshot() -> Dictionary:
	var settings := {"selected_tile": NO_TILE}
	for tile in tile_container.get_children():
		if tile.is_selected:
			settings["selected_tile"] = tile.tile_file_name
			break
	settings["open_directory"] = open_dialog.current_path 
	return settings


func _apply_snapshot(settings: Dictionary):
	var open_directory: String = settings["open_directory"] \
		if "open_directory" in settings else\
		State.current_dir
	open_dialog.current_path = open_directory
#	print(open_directory, " ", State.current_dir)
	load_project_directory(open_directory, settings["selected_tile"])


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
		tile.free()


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


func load_project_directory(directory_path: String, selected_tile: String = NO_TILE):
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
		for tile_fname in tiles_found:
			add_tile_to_tree(directory_path, tile_fname)
		if tile_container.get_child_count() == 0:
			return
		var tile: TPTile = tile_container.get_child(0)
		for tile_in_the_tree in tile_container.get_children():
			if tile_in_the_tree.tile_file_name == selected_tile:
				tile = tile_in_the_tree
				break
		tile.set_selected(true)
		tile.select_root()


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
	State.current_modal_popup = new_tile_dialog
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


func _on_LineEdit_text_entered(_new_text):
	new_tile_dialog.hide()
	new_tile_dialog.emit_signal("confirmed")
	State.current_modal_popup = null


#func _on_ProjectTree_gui_input(event: InputEvent):
#		match event.scancode:
#			KEY_UP:
#				get_tree().set_input_as_handled()
#			KEY_DOWN:
#				get_tree().set_input_as_handled()
