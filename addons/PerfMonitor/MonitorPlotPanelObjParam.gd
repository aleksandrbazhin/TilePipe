extends MonitorPlotPanel


var is_custom_monitor: bool = false
var custom_object_ref: WeakRef = null
var custom_object_parameter: String = ""


func setup_plot(object: Object, param_name: String, label: String, data_max: float,  
		plot_length_frames: int, color: Color, size: Vector2,
		is_data_int: bool = true, is_humanise_needed: bool = false):
	is_custom_monitor = true
	if is_instance_valid(object):
		custom_object_ref = weakref(object)
		var object_param = object.get(param_name)
		if object_param != null and [TYPE_INT, TYPE_REAL].has(typeof(object_param)):
			custom_object_parameter = param_name
		else:
			print("ERROR: passed non-number parameter to perf monitor")
	else: 
		print("ERROR: passed null object to perf monitor")
	.init_plot(label, data_max, plot_length_frames, color, size, is_data_int, is_humanise_needed)


func get_data():
	if is_instance_valid(custom_object_ref.get_ref()):
		return custom_object_ref.get_ref().get(custom_object_parameter)
	else:
		return 0.0
