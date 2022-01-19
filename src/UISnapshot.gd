extends Reference

class_name UISnapshot

const NODE_GROUP_NAME := "snapshottable"

var initiator_ref: WeakRef = null
var state: Dictionary


func _init(initiator: Node):
	initiator_ref = weakref(initiator)


func capture_state():
	var initiator: Node = initiator_ref.get_ref()
	for node in initiator.get_tree().get_nodes_in_group(NODE_GROUP_NAME):
		if initiator == node or initiator.is_a_parent_of(node):
			var key: String = initiator.get_path_to(node)
			var value = get_element_state(node)
			state[key] = value


func apply_state():
	var initiator: Node = initiator_ref.get_ref()
	for node_path in state.keys():
		var value = state[node_path]
		var node = initiator.get_node(node_path)
		if node != null:
			set_element_state(node, value)


func set_element_state(node: Node, value):
	if node.has_method("apply_snapshot"):
		node.apply_snapshot(value)
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
	elif node is SplitContainer:
		node.split_offset = value


func get_element_state(node: Node):
	if node.has_method("take_snapshot"):
		return node.take_snapshot()
	elif node is LineEdit:
		return node.text
	elif node is OptionButton:
		return node.selected
	elif node is CheckButton:
		return node.pressed
	elif node is Range:
		return node.value
	elif node is FileDialog:
		return node.current_path
	elif node is SplitContainer:
		return node.split_offset 
	return null


func get_json() -> String:
	return JSON.print(state, "\t")


func from_dict(dict: Dictionary) -> bool:
	state = dict
	apply_state()
	return true


func from_json(json: String) -> bool:
	var parsed_data = parse_json(json)
	if typeof(parsed_data) == TYPE_DICTIONARY:
		state = parsed_data
		apply_state()
		return true
	return false


func save_to_file(path: String) -> bool:
	var file := File.new()
	if file.open(path, File.WRITE) == OK:
		file.store_string(get_json())
		file.close()
		return true
	return false


func load_from_file(path: String) -> bool:
	var file := File.new()
	if file.open(path, File.READ) == OK:
		var file_text := file.get_as_text()
		file.close()
		if from_json(file_text):
			return true
	return false
