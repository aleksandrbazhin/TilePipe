extends Reference

class_name UISnapshot

const NODE_GROUP_NAME := "snapshottable"
const MIN_SAVE_DELAY_MSEC := 100

var initiator_ref: WeakRef = null
var save_path: String
var _state: Dictionary
var _last_saved_ms: int = 0


func _init(initiator: Node, path: String):
	initiator_ref = weakref(initiator)
	save_path = path


func _set_element_state(node: Node, value):
	if node.has_method("_apply_snapshot"):
		node._apply_snapshot(value)
	elif node is LineEdit:
		node.text = value
	elif node is OptionButton:
		node.selected = value
	elif node is CheckButton:
		node.pressed = value
	elif node is Range:
		node.value = value
	elif node is FileDialog:
		node.current_path = value
		match node.mode:
			FileDialog.MODE_OPEN_DIR:
				node.current_dir = value
				node.emit_signal("dir_selected", node.current_dir)
			FileDialog.MODE_OPEN_FILE, FileDialog.MODE_OPEN_FILES, FileDialog.MODE_OPEN_ANY:
				node.current_path = value
				node.emit_signal("file_selected", node.current_path)
	elif node is SplitContainer:
		node.split_offset = value


func _get_element_state(node: Node):
	if node.has_method("_take_snapshot"):
		return node._take_snapshot()
	elif node is LineEdit:
		return node.text
	elif node is OptionButton:
		return node.selected
	elif node is CheckButton:
		return node.pressed
	elif node is Range:
		return node.value
	elif node is FileDialog:
		var value: String = node.current_path
#		match node.mode:
#			FileDialog.MODE_OPEN_DIR:
#				value = node.current_dir
#			FileDialog.MODE_OPEN_FILE, FileDialog.MODE_OPEN_FILES, FileDialog.MODE_OPEN_ANY:
#				value = node.current_path
		return value
	elif node is SplitContainer:
		return node.split_offset 
	return null


func _watch_element_changes(node: Node):
	if node.has_signal("_snapshot_state_changed"):
		node.connect("_snapshot_state_changed", self, "capture_and_save")
	if node.has_signal("_snapshot_state_changed_continous"):
		node.connect("_snapshot_state_changed_continous", self, "capture_and_save_continuous")
	elif node is LineEdit:
		node.connect("text_changed", self, "capture_and_save")
	elif node is OptionButton:
		node.connect("item_selected", self, "capture_and_save")
	elif node is CheckButton:
		node.connect("toggled", self, "capture_and_save")
	elif node is Range:
		node.connect("value_change", self, "capture_and_save")
	elif node is FileDialog:
		node.connect("dir_selected", self, "capture_and_save")
		node.connect("file_selected", self, "capture_and_save")
		node.connect("files_selected", self, "capture_and_save")
#		match node.mode:
#			FileDialog.MODE_OPEN_DIR:
#				node.connect("dir_selected", self, "capture_and_save")
#			FileDialog.MODE_OPEN_FILE, FileDialog.MODE_OPEN_ANY:
#				node.connect("file_selected", self, "capture_and_save")
#			FileDialog.MODE_OPEN_FILES:
#				node.connect("files_selected", self, "capture_and_save")
	elif node is SplitContainer:
		node.connect("dragged", self, "capture_and_save_continuous")


func _get_json() -> String:
	return JSON.print(_state, "\t")


func _from_json(json: String) -> bool:
	var parsed_data = parse_json(json)
	if typeof(parsed_data) == TYPE_DICTIONARY:
		_state = parsed_data
		apply_state()
		return true
	print("UISnapshot error: cannot parse json data")
	return false


func get_state(node: Node) -> Dictionary:
	var initiator: Node = initiator_ref.get_ref()
	if initiator == node or initiator.is_a_parent_of(node):
		var path:String = initiator.get_path_to(node)
		if _state.has(path):
			return _state[path]
	return {}

func init_snapshot(default_settings: Dictionary = {}):
	var f := File.new()
	if not f.file_exists(save_path):
		if not default_settings.empty():
			_state = default_settings
			apply_state()
	else:
		load_file()
	_init_watchers()


func _init_watchers():
	var initiator: Node = initiator_ref.get_ref()
	initiator.connect("tree_exiting", self, "save_file")
	for node in initiator.get_tree().get_nodes_in_group(NODE_GROUP_NAME):
		if initiator == node or initiator.is_a_parent_of(node):
			_watch_element_changes(node)


func capture_state(_param = null):
	var initiator: Node = initiator_ref.get_ref()
	for node in initiator.get_tree().get_nodes_in_group(NODE_GROUP_NAME):
		if initiator == node or initiator.is_a_parent_of(node):
			var key: String = initiator.get_path_to(node)
			var value = _get_element_state(node)
			if value != null:
				_state[key] = value


func apply_state():
	var initiator: Node = initiator_ref.get_ref()
	for node_path in _state.keys():
		var value = _state[node_path]
		var node = initiator.get_node_or_null(node_path)
		if node != null:
			_set_element_state(node, value)


func capture_continuous(_param = null):
	var time_ms := OS.get_ticks_msec()
	if time_ms - _last_saved_ms > MIN_SAVE_DELAY_MSEC:
		_last_saved_ms = time_ms
		capture_state()


func capture_and_save(_param = null):
	capture_state()
	save_file()


func capture_and_save_continuous(_param = null):
	var time_ms := OS.get_ticks_msec()
	if time_ms - _last_saved_ms > MIN_SAVE_DELAY_MSEC:
		_last_saved_ms = time_ms
		capture_and_save()


func save_file(_param = null) -> bool:
	var file := File.new()
	if file.open(save_path, File.WRITE) == OK:
		file.store_string(_get_json())
		file.close()
		return true
	print("UISnapshot error: cannot save savefile, is user directory accessible?")
	return false


func load_file() -> bool:
	var file := File.new()
	if file.open(save_path, File.READ) == OK:
		var file_text := file.get_as_text()
		file.close()
		if _from_json(file_text):
			return true
	print("UISnapshot error: savefile does not exist, save state first")
	return false
