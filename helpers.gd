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
