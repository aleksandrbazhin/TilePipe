extends Control

class_name TileInTree

signal row_selected(row)

const HEIGHT_EXPANDED := 140
const HEIGHT_COLLAPSED := 44


var tile_name: String
var tree_root: TreeItem
var tree_texture: TreeItem
var tree_ruleset: TreeItem
var tree_template: TreeItem

onready var tree := $Tree
onready var highlight_rect := $ColorRect


func _ready():
	tree_root = tree.create_item()
	tree_root.set_text(0, "Tile %s" % tile_name)
	tree_texture = tree.create_item(tree_root)
	tree_texture.set_text(0, "Texture %s" % tile_name)
	tree_ruleset = tree.create_item(tree_root)
	tree_ruleset.set_text(0, "Ruleset %s" % tile_name)
	tree_template = tree.create_item(tree_root)
	tree_template.set_text(0, "Template %s" % tile_name)
	yield(get_tree(), "idle_frame")
	rect_min_size.y = 140


func _on_Tree_item_selected():
	var selected_row: TreeItem = tree.get_selected()
	if selected_row == tree.get_root():
		tree.get_root().collapsed = false
	emit_signal("row_selected", selected_row)
	set_highlight(true)


func set_highlight(is_highlighted: bool):
	if is_highlighted:
		highlight_rect.show()
	else:
		highlight_rect.hide()


func deselect_except(row: TreeItem):
	var selected_row: TreeItem = tree.get_selected()
	if is_instance_valid(selected_row) and row != selected_row:
		selected_row.deselect(0)
		set_highlight(false)


func _on_Tree_item_collapsed(item: TreeItem):
	if item.collapsed:
		rect_min_size.y = HEIGHT_COLLAPSED
	else:
		rect_min_size.y = HEIGHT_EXPANDED

#
#func _on_Tree_item_rmb_selected(position):
#	var root: TreeItem = tree.get_root()
#	root.collapsed = not root.collapsed
		
