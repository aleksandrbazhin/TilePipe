class_name ProjectTree
extends Panel


signal _snapshot_state_changed()

const NO_TILE := "_no_tile_means_we_select_first_"

var convert_dialog_requested := false

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
onready var no_tiles_found := $NoTilesFound
onready var new_tile_dialog := $NewTileDialog
onready var new_tile_lineedit := $NewTileDialog/CenterContainer/LineEdit
onready var delete_tile_dialog := $DeleteTileDialog
onready var delete_tile_text := $DeleteTileDialog/CenterContainer/Label
onready var open_dialog := $OpenFolderDialog


func _take_snapshot() -> Dictionary:
	var settings := {"selected_tile": NO_TILE}
	for tile in tile_container.get_children():
		if tile.is_selected:
			settings["selected_tile"] = tile.tile_file_name
			break
	settings["open_directory"] = State.current_dir 
	return settings


func _apply_snapshot(settings: Dictionary):
	var open_directory: String = settings["open_directory"] \
		if "open_directory" in settings else State.current_dir
	open_dialog.current_path = open_directory
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
		# Important! - not queue free since otherwise 
		# select first will be called on queued object when openning new dirextory
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
	State.set_current_dir(directory_path)
	dir_edit.text = State.current_dir
	open_dialog.current_path = State.current_dir
	
	clear_tree()
	var tiles_found := scan_directory(State.current_dir)
	if tiles_found.empty():
		no_tiles_found.show()
		State.clear_current_tile()
	else:
		no_tiles_found.hide()
		tiles_found.sort()
		convert_dialog_requested = false
		for tile_fname in tiles_found:
			add_tile_to_tree(State.current_dir, tile_fname, false)
		if get_tile_count() == 0:
			return
		if convert_dialog_requested:
			yield(VisualServer, "frame_post_draw")
			call_ruleset_convert_dialog()
		var tile: TPTile = tile_container.get_child(0)
		for tile_in_the_tree in tile_container.get_children():
			if tile_in_the_tree.tile_file_name == selected_tile:
				tile = tile_in_the_tree
				break
		tile.set_selected(true)
		tile.select_root()


func add_tile_to_tree(directory: String, tile_file: String, is_new: bool, select_position: bool = false) -> TPTile:
	var tile: TPTile = preload("res://src/nodes/TPTile.tscn").instance()
	if tile.load_tile(directory, tile_file, is_new):
		if not tile.is_ruleset_loaded and tile.ruleset != null and tile.ruleset.last_error == Ruleset.ERRORS.OLD_FORMAT:
			convert_dialog_requested = true
		tile.connect("row_selected", self, "on_tile_row_selected", [tile])
		tile.connect("delete_tile_called", self, "start_delete_tile")
		tile.connect("copy_tile_called", self, "copy_tile")
	tile_container.add_child(tile)
	if select_position and tile_container.get_child_count() > 0:
		var insert_position := 0
		for i in tile_container.get_child_count():
			var test_tile: TPTile = tile_container.get_child(i)
			insert_position = i
			if test_tile.tile_file_name > tile_file:
				break
		tile_container.move_child(tile, insert_position)
	return tile


func _on_OpenFolderDialog_dir_selected(dir: String):
	if dir != open_dialog.current_path:
		open_dialog.current_path = dir
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
	var new_tile := add_tile_to_tree(State.current_dir, new_name, true, true)
#	State.set_current_tile(new_tile)
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


func start_delete_tile(tile: TPTile):
	delete_tile_text.text = "  Delete the tile \"%s\" ? (Moves to trash) " % tile.tile_file_name
	delete_tile_dialog.popup_centered()
	State.popup_started(delete_tile_dialog)


func get_tile_count() -> int:
	return tile_container.get_child_count()


func _on_DeleteTileDialog_confirmed():
	var tile := State.get_current_tile()
	if tile != null:
		var tile_count := get_tile_count()
		if tile_count > 1:
			var tile_index := tile.get_index()
			var next_tile: TPTile = tile_container.get_child((tile_index + 1) % tile_count)
			State.call_deferred("set_current_tile", next_tile)
		else:
			State.clear_current_tile()
		OS.move_to_trash(State.current_dir + tile.tile_file_name)
		tile.queue_free()


func _on_DeleteTileDialog_popup_hide():
	State.popup_ended()


func generate_copy_file_name(file_name: String, copy_index: int) -> String:
	return file_name.get_basename() + "_(%d)." % copy_index + file_name.get_extension()


func copy_tile(tile: TPTile):
	var dir := Directory.new()
	if dir.open(State.current_dir) != OK:
		State.report_error("Can not open current directory.")
		return
	var copy_index := 1
	var new_file_name := generate_copy_file_name(tile.tile_file_name, copy_index)
	while dir.file_exists(new_file_name):
		copy_index += 1
		new_file_name = generate_copy_file_name(tile.tile_file_name, copy_index)
	if dir.copy(State.current_dir + tile.tile_file_name,  State.current_dir + new_file_name) != OK:
		State.report_error("Failed to copy tile to \"%s\"" % 
			(State.current_dir + new_file_name))
		return
	add_tile_to_tree(State.current_dir, new_file_name, false, true)


func call_ruleset_convert_dialog():
	var tile_list := tile_container.get_children()
	for i in tile_list.size():
		var tile: TPTile = tile_list[i]
		if not(tile.ruleset != null and tile.ruleset.last_error == Ruleset.ERRORS.OLD_FORMAT):
			tile_list[i] = null
	$RulesetConvertDialog.list_rulesets(tile_list)
	$RulesetConvertDialog.popup_centered()


func _on_RulesetConvertDialog_popup_hide():
	State.popup_ended()


func _on_RulesetConvertDialog_confirmed():
	yield(VisualServer, "frame_post_draw")
	load_project_directory(State.current_dir)
