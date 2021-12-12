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
	var d := Directory.new()
	return d.dir_exists(path)

# snap to closest bigger power of 2, for less than 1 x returns snapped fraction
func snap_up_to_po2(x: float) -> float:
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x))))
	else:
		return 1.0/float(nearest_po2(int(floor(1.0/x))))

func snap_down_to_po2(x: float) -> float:
	if x >= 1.0:
		return float(nearest_po2(int(ceil(x)))) / 2.0
	else:
		return 1.0/float(nearest_po2(int(ceil(1.0/x))))
