extends MonitorPlotPanel


var is_funcref_monitor: bool = false
var custom_funcref: FuncRef = null
var custom_funcref_params: Array = []


func setup_plot(function_ref: FuncRef, 
		function_params: Array, label: String, data_max: float,  
		plot_length_frames: int, color: Color, size: Vector2, 
		is_data_int: bool = true, is_humanise_needed: bool = false):
	is_funcref_monitor = true
	if is_instance_valid(instance_from_id(function_ref.get_instance_id())):
		var func_value = function_ref.call_funcv(function_params)
		if func_value != null and [TYPE_INT, TYPE_REAL].has(typeof(func_value)):
			custom_funcref = function_ref
			custom_funcref_params = function_params
		else:
			print("ERROR: funcref passed to performance monitor returns non-number parameter")
	else: 
		print("ERROR: passed not a valid object to funcref to performance monitor")
	.init_plot(label, data_max, plot_length_frames, color, size, is_data_int, is_humanise_needed)


func get_data():
	if custom_funcref != null and is_instance_valid(instance_from_id(custom_funcref.get_instance_id())):
			return custom_funcref.call_funcv(custom_funcref_params)
	else:
		return 0.0

