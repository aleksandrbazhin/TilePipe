extends Control

class_name TileInTree

signal row_selected(row)


var tile_name: String
var tree_root: TreeItem
var tree_texture: TreeItem
var tree_ruleset: TreeItem
var tree_template: TreeItem

onready var tree := $Tree


func _ready():
	tree_root = tree.create_item()
	tree_root.set_text(0, "Tile %s" % tile_name)
	tree_texture = tree.create_item(tree_root)
	tree_texture.set_text(0, "Texture %s" % tile_name)
	tree_ruleset = tree.create_item(tree_root)
	tree_ruleset.set_text(0, "Ruleset %s" % tile_name)
	tree_template = tree.create_item(tree_root)
	tree_template.set_text(0, "Template %s" % tile_name)


func _on_Tree_item_selected():
	var selected_row: TreeItem = tree.get_selected()
	emit_signal("row_selected", selected_row)


func deselect_except(row: TreeItem):
	var selected_row: TreeItem = tree.get_selected()	
	if is_instance_valid(selected_row) and row != selected_row:
		selected_row.deselect(0)
