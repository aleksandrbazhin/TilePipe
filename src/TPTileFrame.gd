extends Reference

class_name TPTileFrame

var parsed_template := {}
var result_subtiles_by_bitmask := {}
var result_texture: Texture


func append_subtile(mask: int, pos: Vector2):
	if not result_subtiles_by_bitmask.has(mask):
		result_subtiles_by_bitmask[mask] = []
	var subtile := GeneratedSubTile.new(mask, pos)
	result_subtiles_by_bitmask[mask].append(subtile)
	parsed_template[pos] = weakref(subtile)


func set_result_texture(tex: Texture):
	result_texture = tex
