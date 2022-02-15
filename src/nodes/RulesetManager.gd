extends PopupDialog

class_name RulesetMananger

onready var builtin_rulesets := $VBoxContainer/HBoxContainer/BuiltInRulesets/MarginContainer/PanelContainer/ScrollContainer/BuiltInList
onready var custom_rulesets := $VBoxContainer/HBoxContainer/CustomRulesets/MarginContainer/PanelContainer/ScrollContainer/CustomList


func _on_Button_pressed():
	hide()


func _on_RulesetDialog_about_to_show():
	populate_lists()


func populate_lists():
	for row in builtin_rulesets.get_children():
		row.queue_free()
	for row in custom_rulesets.get_children():
		row.queue_free()
	
	var rulesets_found := get_rulesets_in_project()
	var existing_ruleset_filenames := []
	for ruleset_path in rulesets_found:
		existing_ruleset_filenames.append(ruleset_path.get_file())
	var builtin_ruleset_filenames := []
	for ruleset_path in Const.BUILT_IN_RULESETS:
		builtin_ruleset_filenames.append(ruleset_path.get_file())
		
	for ruleset_path in builtin_ruleset_filenames:
		var ruleset_row := CheckBox.new()
		ruleset_row.text = ruleset_path.get_file()
		ruleset_row.rect_min_size.y = 40
		builtin_rulesets.add_child(ruleset_row)
		if existing_ruleset_filenames.has(ruleset_path):
			ruleset_row.pressed = true
	
#
#	for ruleset_path in rulesets_found:
#		var ruleset_row := CheckBox.new()
#		ruleset_row.text = ruleset_path.get_file()
#		ruleset_row.rect_min_size.y = 40
#		builtin_rulesets.add_child(ruleset_row)


func scan_for_rulesets_in_project(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "json":
			files.append(path + "/" + file)
	dir.list_dir_end()
	return files


func get_rulesets_in_project() -> PoolStringArray:
	var rulesets_found := scan_for_rulesets_in_project(Const.current_dir)
	rulesets_found += scan_for_rulesets_in_project(Const.current_dir + "/rulesets")
	return rulesets_found
	
