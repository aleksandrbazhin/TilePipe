extends Node

class_name GodotExporter

func save_resource(path: String, tile_size: int, tile_masks: Array, 
		is_autotile: bool, texture_size := Vector2.ZERO, with_description: bool = false):
	var output_string : String
	if is_autotile:
		output_string = make_autotile_resource_data(path, tile_size, tile_masks, texture_size)
	else:
		output_string = make_manual_resource_data(path, tile_size, tile_masks, with_description)
	var tileset_resource_path: String = path.get_basename( ) + ".tres"
	var file = File.new()
	file.open(tileset_resource_path, File.WRITE)
	file.store_string(output_string)
	file.close()

func tile_name_from_position(pos: Vector2) -> String:
	return "%d_%d" % [pos.x, pos.y]

func make_manual_resource_data(path: String, tile_size: int, tile_masks: Array, with_description: bool) -> String:
#	var tile_size: int = get_output_size()
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=3 format=2]\n"
	out_string += "\n[ext_resource path=\"%s\" type=\"Texture\" id=1]\n" % path
#	if export_manual_resource_type_select.pressed:
	if with_description:
		out_string += "[ext_resource path=\"res://addons/TilePipe/tilesheet_description.gd\" type=\"Script\" id=2]\n"
	out_string += "\n[resource]\n"
	var count: int = 0
	var tile_lines: PoolStringArray = []
	var tile_description_lines: PoolStringArray = []
	for mask in tile_masks:
		var pos: Vector2 = mask["position"]
		tile_lines.append("%d/name = \"%s\"" % [count, tile_name_from_position(pos)])
		tile_lines.append("%d/texture = ExtResource( 1 )" % count)
		tile_lines.append("%d/tex_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/modulate = Color( 1, 1, 1, 1 )" % count)
		tile_lines.append("%d/region = Rect2( %d, %d, %d, %d )" % [count, 
						tile_size * pos.x, tile_size * pos.y, tile_size, tile_size])
		tile_lines.append("%d/tile_mode = 0" % count)
		tile_lines.append("%d/occluder_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/navigation_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/shape_offset = Vector2( 0, 0 )" % count)
		tile_lines.append("%d/shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )" % count)
		tile_lines.append("%d/shape_one_way = false" % count)
		tile_lines.append("%d/shape_one_way_margin = 0.0" % count)
		tile_lines.append("%d/shapes = [  ]" % count)
		tile_lines.append("%d/z_index = 0" % count)
		count += 1
		tile_description_lines.append("%d: \"%s\"" % [mask['godot_mask'], tile_name_from_position(pos)])
	out_string += tile_lines.join("\n")
	if with_description:
		out_string += "\nscript = ExtResource( 2 )\nreplacements_table = {\n"
		out_string += tile_description_lines.join(",\n")
		out_string += "\n}"
	return out_string

func make_autotile_resource_data(path: String, tile_size: int, tile_masks: Array, texture_size: Vector2) -> String:
	var out_string: String = "[gd_resource type=\"TileSet\" load_steps=3 format=2]\n"
	out_string += "\n[ext_resource path=\"%s\" type=\"Texture\" id=1]\n" % path
	out_string += "\n[resource]\n"
#	var texture_size: Vector2 = out_texture.texture.get_data().get_size()
	var mask_out_array: PoolStringArray = []
	for mask in tile_masks:
		mask_out_array.append("Vector2 ( %d, %d )" % [mask['position'].x, mask['position'].y])
		mask_out_array.append(mask['godot_mask'])
	out_string += "0/name = \"0_0\"\n"
	out_string += "0/texture = ExtResource( 1 )\n"
	out_string += "0/tex_offset = Vector2( 0, 0 )\n"
	out_string += "0/modulate = Color( 1, 1, 1, 1 )\n"
	out_string += "0/region = Rect2( 0, 0, %d, %d )\n" % [texture_size.x, texture_size.y]
	out_string += "0/tile_mode = 1\n"
	out_string += "0/autotile/bitmask_mode = 1\n"
	out_string += "0/autotile/bitmask_flags = [%s]\n" % mask_out_array.join(", ")
	out_string += "0/autotile/icon_coordinate = Vector2( 0, 0 )\n"
	out_string += "0/autotile/tile_size = Vector2( %d, %d )\n" % [tile_size, tile_size]
	out_string += "0/autotile/spacing = 0\n"
	out_string += "0/autotile/occluder_map = [  ]\n"
	out_string += "0/autotile/navpoly_map = [  ]\n"
	out_string += "0/autotile/priority_map = [  ]\n"
	out_string += "0/autotile/z_index_map = [  ]\n"
	out_string += "0/occluder_offset = Vector2( 0, 0 )\n"
	out_string += "0/navigation_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_offset = Vector2( 0, 0 )\n"
	out_string += "0/shape_transform = Transform2D( 1, 0, 0, 1, 0, 0 )\n"
	out_string += "0/shape_one_way = false\n"
	out_string += "0/shape_one_way_margin = 0.0\n"
	out_string += "0/shapes = [  ]\n"
	out_string += "0/z_index = 0\n"
	return out_string

#const IGNORE_GODOT_MASK: int = Const.GODOT_MASK["TOP_LEFT"] | Const.GODOT_MASK["TOP_RIGHT"] | \
#			Const.GODOT_MASK["BOTTOM_LEFT"] | Const.GODOT_MASK["BOTTOM_LEFT"] | Const.GODOT_MASK["CENTER"]
#func compute_tile_replacement_data() -> Dictionary:
#	var data: Dictionary = {}
#	for mask in tile_masks:
#		data[mask["godot_mask"]] = tile_name_from_position(mask["position"])
#	return data
