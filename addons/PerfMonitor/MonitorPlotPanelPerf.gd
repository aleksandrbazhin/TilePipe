extends MonitorPlotPanel


var perf_monitor_key: int = Performance.TIME_FPS


func setup_plot(monitor_key: int, label: String, data_max: float, 
		plot_length_frames: int, color: Color, size: Vector2, 
		is_data_int: bool = true, is_humanise_needed: bool = false):
	perf_monitor_key = monitor_key
	.init_plot(label, data_max, plot_length_frames, color, size, is_data_int, is_humanise_needed)


func get_data():
	return Performance.get_monitor(perf_monitor_key)
