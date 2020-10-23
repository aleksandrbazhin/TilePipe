extends CanvasLayer


const SCREEN_MARGIN: = 4
const DEFAULT_DATA_LEN: = 180 # in frames of _process calls
const DEFAULT_PLOT_COLOR: = Color(0.2, 1, 0.2, 0.5)
const DEFAULT_PLOT_SIZE: = Vector2(180, 80)
const DEFAULT_DATA_MAX: = 1.0

onready var plot_scene_perf: PackedScene = preload("MonitorPlotPanelPerf.tscn")
onready var plot_scene_custom: PackedScene = preload("MonitorPlotPanelObjParam.tscn")
onready var plot_scene_funcref: PackedScene = preload("MonitorPlotPanelFuncref.tscn")

var plot_panels_node: HBoxContainer


var last_usec: int = 0
func get_frame_time() -> float:
	var usec_delta: int = OS.get_ticks_usec() - last_usec
	last_usec += usec_delta
	return float(usec_delta) / 1000000.0


# preset
func os_time_per_frame():
	add_funcref_monitor(funcref(self, "get_frame_time"), [], "OS time / frame, s", 
		DEFAULT_PLOT_COLOR, false, false, 0.0)


func _ready():
	init_nodes()


func init_nodes():
	var margin_container = MarginContainer.new()
	margin_container.set("custom_constants/margin_top", SCREEN_MARGIN)
	margin_container.set("custom_constants/margin_bottom", SCREEN_MARGIN)
	margin_container.set("custom_constants/margin_left", SCREEN_MARGIN)
	margin_container.set("custom_constants/margin_right", SCREEN_MARGIN)
	var hbox_container = HBoxContainer.new()
	hbox_container.set("custom_constants/separation", SCREEN_MARGIN / 2)
	margin_container.add_child(hbox_container)
	add_child(margin_container)
	plot_panels_node = hbox_container


func add_perf_monitor(param_key: int, 
					label: String = "",  
					color: Color = DEFAULT_PLOT_COLOR, 
					humanise: bool = false, 
					is_data_int: bool = true, 
					max_value: float = DEFAULT_DATA_MAX,
					data_len: int = DEFAULT_DATA_LEN, 
					size_px: Vector2 = DEFAULT_PLOT_SIZE):
	var new_plot: MonitorPlotPanel = plot_scene_perf.instance()
	plot_panels_node.add_child(new_plot)
	new_plot.setup_plot(param_key, label, max_value, data_len, color, size_px, is_data_int, humanise)


func add_custom_monitor(obj: Object, param_name: String, 
					label: String = "",  
					color: Color = DEFAULT_PLOT_COLOR, 
					humanise: bool = false, 
					is_data_int: bool = true, 
					max_value: float = DEFAULT_DATA_MAX,
					data_len: int = DEFAULT_DATA_LEN, 
					size_px: Vector2 = DEFAULT_PLOT_SIZE):
	var new_plot: MonitorPlotPanel = plot_scene_custom.instance()
	plot_panels_node.add_child(new_plot)
	new_plot.setup_plot(obj, param_name, label, max_value, data_len, color, size_px, is_data_int, humanise)


func add_funcref_monitor(function_ref: FuncRef, function_params: Array = [], 
					label: String = "",  
					color: Color = DEFAULT_PLOT_COLOR, 
					humanise: bool = false, 
					is_data_int: bool = true, 
					max_value: float = DEFAULT_DATA_MAX,
					data_len: int = DEFAULT_DATA_LEN, 
					size_px: Vector2 = DEFAULT_PLOT_SIZE):
	var new_plot: MonitorPlotPanel = plot_scene_funcref.instance()
	plot_panels_node.add_child(new_plot)
	new_plot.setup_plot(function_ref, function_params, label, max_value, data_len, color, size_px, is_data_int, humanise)
