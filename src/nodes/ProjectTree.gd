extends Panel

class_name ProjectTree

signal texture_selected(tile_name)
signal ruleset_selected(tile_name)
signal template_selected(tile_name)


onready var tile_container := $MarginContainer/VBoxContainer/TileScrollContainer/TileVBoxContainer
onready var dir_edit := $MarginContainer/VBoxContainer/HBoxContainer/DirLineEdit

func add_tile_to_tree(tile_name: String):
	var tile := preload("res://src/nodes/TileInTree.tscn").instance()
	tile.tile_name = tile_name
	tile.connect("row_selected", self, "on_tile_row_selected", [tile])
	tile_container.add_child(tile)


func on_tile_row_selected(row: TreeItem, tile: TileInTree):
	for tile in tile_container.get_children():
		tile.deselect_except(row)
	match row:
		tile.tree_root, tile.tree_texture:
			emit_signal("texture_selected", tile.tile_name)
		tile.tree_ruleset:
			emit_signal("ruleset_selected", tile.tile_name)
		tile.tree_template:
			emit_signal("template_selected", tile.tile_name)


func load_project_directory(dir: String):
	for tile in tile_container.get_children():
		tile.queue_free()
	dir_edit.text = dir
	add_tile_to_tree("MyFirstTile")
	add_tile_to_tree("MySecondTile")
	add_tile_to_tree("MyThirdTile")


func _on_OpenFolderDialog_dir_selected(dir: String):
	load_project_directory(dir)


func _on_DirLoadButton_pressed():
	$OpenFolderDialog.popup_centered()
