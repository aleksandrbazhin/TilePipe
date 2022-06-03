extends Panel


signal _snapshot_state_changed_continous()

var VERSION: String = ProjectSettings.get_setting("application/config/version")
var is_ui_blocked: bool = false
var rng := RandomNumberGenerator.new()
var last_dragged := 0
var ui_snapshot: UISnapshot

onready var project_tree: ProjectTree = $VBoxContainer/HSplitContainer/ProjectContainer/ProjectTree
onready var blocking_overlay := $BlockingOverlay
onready var work_zone: WorkZone = $VBoxContainer/HSplitContainer/WorkZone
onready var error_dialog: AcceptDialog = $ErrorDialog


func _ready():
#	OS.window_fullscreen = false
#	OS.window_borderless = false
	connect_signals()
	OS.min_window_size = Const.MIN_WINDOW_SIZE
	ui_snapshot = UISnapshot.new(self, Const.SETTINGS_PATH)
	ui_snapshot.init_snapshot(Const.DEFAULT_USER_SETTINGS)
	var mode := "Debug" if OS.is_debug_build() else "Release"
	print("TilePipe v%s running in %s mode" % [VERSION, mode])
	OS.set_window_title("TilePipe v.%s" % VERSION)
	rng.randomize()
	error_dialog.get_label().align = Label.ALIGN_CENTER



func connect_signals():
	State.connect("tile_selected", work_zone, "on_tile_selected")
	State.connect("tile_updated", work_zone, "render_subtiles")
	State.connect("popup_started", self, "start_modal_popup")
	State.connect("popup_ended", self, "end_modal_popup")
	State.connect("report_error", self, "add_error_report")
	get_tree().get_root().connect("size_changed", self, "on_size_changed")


func _take_snapshot() -> Dictionary:
	return {
		"window_maximized": OS.window_maximized,
		"window_position": var2str(OS.window_position),
		"window_size": var2str(OS.window_size)
	}


func _apply_snapshot(settings: Dictionary):
	if settings["window_maximized"]:
		OS.window_maximized = true
	else:
		OS.window_maximized = false
		OS.window_position = str2var(settings["window_position"])
		OS.window_size = str2var(settings["window_size"])


func on_size_changed():
	var saved_state := ui_snapshot.get_state(self)
	if not saved_state.empty():
		if saved_state["window_position"] != var2str(OS.window_position) or \
				saved_state["window_maximized"] != OS.window_maximized or \
				saved_state["window_size"] != var2str(OS.window_size):
			emit_signal("_snapshot_state_changed_continous")


func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		if State.current_modal_popup != null:
			State.current_modal_popup.hide()


func start_modal_popup():
	blocking_overlay.show()


func end_modal_popup():
	blocking_overlay.hide()


func add_error_report(text: String):
	start_modal_popup()
	error_dialog.dialog_text += text + "\n"
	error_dialog.popup_centered_clamped()


func _on_ErrorDialog_popup_hide():
	end_modal_popup()
	error_dialog.dialog_text = ""
