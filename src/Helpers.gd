extends Node


func get_default_dir_path() -> String:
#	report_error(OS.get_name()+"  "+OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
	if OS.get_name() == "OSX":
		return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	else:
		return OS.get_executable_path().get_base_dir()


func clear_path(path: String) -> String:
	if path.begins_with("res://"):
		return get_default_dir_path() + "/" + path.get_file()
	else:
		return path


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

