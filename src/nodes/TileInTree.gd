extends Control

class_name TileInTree

signal row_selected(row)
signal error_loading()

const HEIGHT_EXPANDED := 144
const HEIGHT_COLLAPSED := 50

var is_loaded := false
var tile_data: Dictionary
var current_directory: String
var tile_file_name: String
var is_selected := false

var tile_row: TreeItem
var texture_row: TreeItem
var ruleset_row: TreeItem
var template_row: TreeItem

onready var tree := $Tree
onready var highlight_rect := $ColorRect


func _ready():
	if is_loaded:
		create_tree_items()
		rect_min_size.y = HEIGHT_EXPANDED


func load_file(directory: String, tile_file: String):
	current_directory = directory
	tile_file_name = tile_file
	var path := directory + "/" + tile_file
	var file := File.new()
	file.open(path, File.READ)
	var file_text := file.get_as_text()
	file.close()
	var parsed_data = parse_json(file_text)
	if typeof(parsed_data) == TYPE_DICTIONARY:
		tile_data = parsed_data
		is_loaded = true
	else:
		emit_signal("error_loading")
		return
	

func create_tree_items():
	tile_row = tree.create_item()
	tile_row.set_text(0, tile_file_name)
	add_texture_item(tile_data["texture"])
	add_ruleset_item(tile_data["ruleset"])
	add_template_item(tile_data["template"])


func add_texture_item(file_name: String):
	texture_row = tree.create_item(tile_row)
	texture_row.set_text(0, "Texture: %s" % file_name)


func add_ruleset_item(file_name: String):
	ruleset_row = tree.create_item(tile_row)
	ruleset_row.set_text(0, "Ruleset: %s" % file_name)


func add_template_item(file_name: String):
	template_row = tree.create_item(tile_row)
	template_row.set_text(0, "Template: %s" % file_name)


func _on_Tree_item_selected():
	var selected_row: TreeItem = tree.get_selected()
	if selected_row == tree.get_root():
		tree.get_root().collapsed = false
	emit_signal("row_selected", selected_row)
	set_selected(true)


func select_root():
	tree.get_root().select(0)


func set_selected(selected: bool):
	if selected:
		highlight_rect.show()
		is_selected = true
	else:
		highlight_rect.hide()
		is_selected = false


func deselect_except(row: TreeItem):
	var selected_row: TreeItem = tree.get_selected()
	if is_instance_valid(selected_row) and row != selected_row:
		selected_row.deselect(0)
		set_selected(false)


func _on_Tree_item_collapsed(item: TreeItem):
	if item.collapsed:
		rect_min_size.y = HEIGHT_COLLAPSED
	else:
		rect_min_size.y = HEIGHT_EXPANDED

#
#func _on_Tree_item_rmb_selected(position):
#	var root: TreeItem = tree.get_root()
#	root.collapsed = not root.collapsed
		
