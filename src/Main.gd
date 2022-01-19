extends Panel

var VERSION: String = ProjectSettings.get_setting("application/config/version")
var is_ui_blocked: bool = false
var rng := RandomNumberGenerator.new()
#var is_dragged := false
var last_dragged := 0
var user_settings: UISnapshot


onready var project_tree: ProjectTree = $VBoxContainer/HSplitContainer/MarginContainer/ProjectTree
onready var blocking_overlay := $BlockingOverlay


func _ready():
#	OS.window_fullscreen = false
	OS.window_borderless = false
	OS.min_window_size = Const.MIN_WINDOW_SIZE
	user_settings = UISnapshot.new(self)
	init_from_user_settings()
	var mode := "Debug" if OS.is_debug_build() else "Release"
	print("TilePipe v%s running in %s mode" % [VERSION, mode])
	OS.set_window_title("TilePipe v.%s" % VERSION)
	rng.randomize()
	connect_signals()


func connect_signals():
	project_tree.connect("file_dialog_started", blocking_overlay, "show")
	project_tree.connect("file_dialog_ended", blocking_overlay, "hide")
	project_tree.connect("file_dialog_ended", user_settings, "capture_state")
	get_tree().get_root().connect("size_changed", self, "on_dragged")


func init_from_user_settings():
	if not Helpers.file_exists(Const.SETTINGS_PATH):
		user_settings.from_dict(Const.DEFAULT_USER_SETTINGS)
	else:
		user_settings.load_from_file(Const.SETTINGS_PATH)


func _exit_tree():
	user_settings.capture_state()
	user_settings.save_to_file(Const.SETTINGS_PATH)


func take_snapshot():
	var settings: Dictionary = Const.DEFAULT_USER_SETTINGS["."].duplicate()
	settings["window_maximized"] = OS.window_maximized
	settings["window_position"] = var2str(OS.window_position)
	settings["window_size"] = var2str(OS.window_size)
	return settings


func apply_snapshot(settings: Dictionary):
	if settings["window_maximized"]:
		OS.window_maximized = true
	else:
		OS.window_maximized = false
		OS.window_position = str2var(settings["window_position"])
		OS.window_size = str2var(settings["window_size"])


func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		if project_tree.is_file_dialog_active:
			project_tree.hide_file_dialog()
#			popup_dialog.hide()
#		elif godot_export_dialog.visible:
#			godot_export_dialog.cancel_action()
#		elif texture_file_dialog.visible:
#			texture_file_dialog.hide()
#		elif template_file_dialog.visible:
#			template_file_dialog.hide()
#		elif save_texture_dialog.visible:
#			save_texture_dialog.hide()
#		else:
#			exit()


func on_dragged(offset = null): 
	var time := OS.get_ticks_msec()
	if time - last_dragged > Const.DRAG_END_MSEC:
		last_dragged = time
		user_settings.capture_state()
		user_settings.save_to_file(Const.SETTINGS_PATH)
		
