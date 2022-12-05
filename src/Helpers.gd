extends Node


func file_exists(path: String) -> bool:
	var f := File.new()
	return f.file_exists(path)


func dir_exists(path: String) -> bool:
	var dir := Directory.new()
	return dir.dir_exists(path)


func ensure_directory_exists(parent_path: String, dir_name: String) -> bool:
	var dir := Directory.new()
	var dir_path := parent_path + "/" + dir_name
	if not dir.dir_exists(dir_path):
		dir.open(parent_path)
		var dir_error := dir.make_dir(dir_name)
		if dir_error != OK:
			return false
	return true


# snap to closest bigger power of 2, for less than 1 x returns snapped fraction
func snap_up_to_po2(x: float) -> float:
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x))))
	else:
		return 1.0/float(nearest_po2(int(floor(1.0/x))))


func snap_down_to_po2(x: float) -> float:
	if x == 0.0:
		return 0.0
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x)))) / 2.0
	else:
		return 1.0/float(nearest_po2(int(ceil(1.0/x))))


func rotate_mask_ccw(in_rot: int, quarters: int = 1) -> int:
	var out: int = int(clamp(in_rot, 0, 6)) - 2 * quarters
	out = out % 8
	if out < 0:
		out = 8 + out
	return out


func rotate_mask_cw(in_rot: int, quarters: int = 1) -> int:
	var out: int = int(clamp(in_rot, 0, 6)) + 2 * quarters
	out = out % 8
	return out


func rotate_check_mask(mask: int, rot: int) -> int:
	var rotated_check: int = mask << rot
	if rotated_check > 255:
		var overshoot: int = rotated_check >> 8
		rotated_check ^= overshoot << 8
		rotated_check |= overshoot
	return rotated_check


# returns all rotations for mask which satisfy both templates
#func check_mask_template(pos_check_mask: int, neg_check_mask: int, current_mask: int) -> Array:
# quarters_offset - это количество поворотов на 90 от квадрата (0,0) для положения на картинке (если как на картинке ставим налево вверх, то 0)
func get_allowed_mask_rotations(pos_check_mask: int, neg_check_mask: int, current_mask: int, quarters_offset: int = 0) -> Array:
	var rotations: Array = []
	for rotation in Const.ROTATION_SHIFTS:
		var rotated_check: int = rotate_check_mask(pos_check_mask, rotation)
		var satisfies_check := false
		if current_mask & rotated_check == rotated_check:
			satisfies_check = true
		if satisfies_check and neg_check_mask != 0: # check negative mask
			rotated_check = rotate_check_mask(neg_check_mask, rotation)
			var inverted_check: int = (~rotated_check & 0xFF)
#			print("%s: %s %s %s" % [str(rotation), str(rotated_check), 
#				str(inverted_check),
#				str(current_mask & inverted_check)])
			if current_mask | inverted_check != inverted_check:
				satisfies_check = false
		if satisfies_check:
			rotations.append(rotation)
	return rotations


func convert_bitmask_to_godot(bitmask: int, 
		godot_autotile_type: int = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3) -> int:
	var godot_bitmask: int = 0
	match godot_autotile_type:
		Const.GODOT_AUTOTILE_TYPE.BLOB_3x3, Const.GODOT_AUTOTILE_TYPE.FULL_3x3:
			for mask_name in Const.GODOT_MASK_3x3.keys():
				if mask_name == "CENTER":
#					if has_center:
					godot_bitmask += Const.GODOT_MASK_3x3["CENTER"]
				else:
					var check_bit: int = Const.TILE_MASK[mask_name]
					if bitmask & check_bit != 0:
						godot_bitmask += Const.GODOT_MASK_3x3[mask_name]
		Const.GODOT_AUTOTILE_TYPE.WANG_2x2:
			for mask_name in Const.GODOT_MASK_2x2.keys():
				var check_bit: int = Const.TILE_MASK[mask_name]
				if bitmask & check_bit != 0:
					godot_bitmask += Const.GODOT_MASK_2x2[mask_name]
	return godot_bitmask


func assume_godot_autotile_type(tiles_by_bitmask: Dictionary) -> int:
	var type: int = Const.GODOT_AUTOTILE_TYPE.WANG_2x2
	for mask in tiles_by_bitmask:
		if not tiles_by_bitmask[mask].empty():
			if not mask in Const.GODOT_AUTOTILE_BITMASKS[Const.GODOT_AUTOTILE_TYPE.WANG_2x2]:
				type = Const.GODOT_AUTOTILE_TYPE.BLOB_3x3
				if not mask in Const.GODOT_AUTOTILE_BITMASKS[Const.GODOT_AUTOTILE_TYPE.BLOB_3x3]:
					return Const.GODOT_AUTOTILE_TYPE.FULL_3x3
	return type


func is_file_a_ruleset(path: String) -> bool:
	var file := File.new()
	if file.open(path, File.READ) == OK:
		var json_text := file.get_as_text()
		file.close()
		var parsed_data = parse_json(json_text)
		return typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("ruleset_name")
	return false


func populate_project_file_option(option_button: OptionButton, 
		search_dir: String, search_function: FuncRef, selected_path: String):
	option_button.clear()
	var options_found: PoolStringArray = search_function.call_func(search_dir)
	var sorted_options := Array(options_found)
	sorted_options.sort()
	var index := 0
	for option_path in sorted_options:
		option_button.add_item(option_path.get_file())
		option_button.set_item_metadata(index, option_path)
		if option_path == selected_path:
			option_button.selected = index
		index += 1
	option_button.add_item("No")
	option_button.set_item_metadata(index, "")
	if selected_path.empty():
		option_button.selected = option_button.get_item_count() - 1
	


func scan_for_rulesets_in_dir(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "json":
			var file_path: String = path + file
			if Helpers.is_file_a_ruleset(file_path):
				files.append(file_path)
	dir.list_dir_end()
	return files


func scan_for_templates_in_dir(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "png":
			files.append(path + file)
	dir.list_dir_end()
	return files


func scan_for_textures_in_dir(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file.begins_with("."):
			continue
		elif file == "":
			break
		elif dir.dir_exists(file) and file != Const.TEMPLATE_DIR.rstrip("/") and file != Const.RULESET_DIR.rstrip("/"):
			files.append_array(scan_for_textures_in_dir(path + file + "/" ))
		elif file.get_extension() == "png":
			files.append(path + file)
	dir.list_dir_end()
	return files


func get_closest_output_size_key(size: Vector2) -> int:
	var size_key: int = Const.OUTPUT_TILE_SIZE_OPTIONS.keys().find(int(size.x))
	return size_key if size_key != -1 else 0
