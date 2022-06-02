extends Node

signal tile_selected(tile_node, row_item)
signal tile_updated()


var current_dir := OS.get_executable_path().get_base_dir() + "/" + Const.EXAMPLES_DIR
var current_tile_ref: WeakRef = null


func set_current_tile(tile: TileInTree, row: TreeItem):
	if State.current_tile_ref == null or State.current_tile_ref.get_ref() != tile:
		State.current_tile_ref = weakref(tile)
	emit_signal("tile_selected", tile, row)


func update_tile_overlap_level(level: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_overlap_level(level)
	tile.save()
	emit_signal("tile_updated")


func update_tile_merge_level(level: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_merge_level(level)
	tile.save()
	emit_signal("tile_updated")


func update_tile_size(size: Vector2):
	var tile: TileInTree = current_tile_ref.get_ref()
	if tile.input_tile_size != size:
		tile.set_input_tile_size(size)
		tile.save()
		emit_signal("tile_updated")


func update_tile_texture(path: String):
	var tile: TileInTree = current_tile_ref.get_ref()
	tile.set_texture(path)
	tile.save()
	emit_signal("tile_updated")
