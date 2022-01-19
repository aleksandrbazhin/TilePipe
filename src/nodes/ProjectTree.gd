extends Panel

class_name ProjectTree


signal file_dialog_started()
signal file_dialog_ended()
signal tile_selected(tile_name)
signal texture_selected(tile_name)
signal ruleset_selected(tile_name)
signal template_selected(tile_name)

var is_file_dialog_active := false

onready var tile_container := $VBoxContainer/MarginContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $VBoxContainer/HBoxContainer/DirLineEdit
onready var open_project_dialog := $OpenFolderDialog
onready var no_tiles_found := $NoTilesFound


#func take_snapshot():
#	pass
#


func apply_snapshot(data):
	open_project_dialog.emit_signal("dir_selected", open_project_dialog.current_dir)


func on_tile_row_selected(row: TreeItem, tile: TileInTree):
	for tile in tile_container.get_children():
		tile.deselect_except(row)
	match row:
		tile.tree_root:
			emit_signal("tile_selected", tile)
		tile.tree_texture:
			emit_signal("texture_selected", tile)
		tile.tree_ruleset:
			emit_signal("ruleset_selected", tile)
		tile.tree_template:
			emit_signal("template_selected", tile)


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
	clear_tree()
	var tiles_found := scan_directory(directory_path)
	if tiles_found.empty():
		no_tiles_found.show()
	else:
		no_tiles_found.hide()
		for tile_fname in tiles_found:
			add_tile_to_tree(directory_path, tile_fname)


func add_tile_to_tree(directory: String, tile_file: String):
	var tile: TileInTree = preload("res://src/nodes/TileInTree.tscn").instance()
	tile.load_file(directory, tile_file)
	tile.connect("row_selected", self, "on_tile_row_selected", [tile])
	tile_container.add_child(tile)


func _on_OpenFolderDialog_dir_selected(dir: String):
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
