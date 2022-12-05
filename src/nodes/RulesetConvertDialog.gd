extends ConfirmationDialog


func list_rulesets(loaded_tiles: Array):
	for line_edit in $MarginContainer/VBoxContainer/VBoxContainer.get_children():
		line_edit.queue_free()
	for tile in loaded_tiles:
		if tile == null:
			continue
		var l := LineEdit.new()
		l.editable = false
		l.text = tile.ruleset_path
		$MarginContainer/VBoxContainer/VBoxContainer.add_child(l)


func _on_ButtonCancel_pressed():
	hide()


func _on_RulesetConvertDialog_confirmed():
	var type_re := RegEx.new()
	type_re.compile(',\\n\\s*"ruleset_description"')
	var rules_re := RegEx.new()
	rules_re.compile('"tiles":')
	var indexes_re := RegEx.new()
	indexes_re.compile('"part_indexes":\\s*\\[')
	var rot_re := RegEx.new()
	rot_re.compile('"part_rotations":\\s*\\[')
	var flip_x_re := RegEx.new()
	flip_x_re.compile('"part_flip_x":\\s*\\[')
	var flip_y_re := RegEx.new()
	flip_y_re.compile('"part_flip_y":\\s*\\[')


	for line_edit in $MarginContainer/VBoxContainer/VBoxContainer.get_children():
		var path: String = line_edit.text
		var file = File.new()
		if not file.file_exists(path):
			continue
		file.open(path, File.READ_WRITE)
		var data_string: String = file.get_as_text()
		data_string = type_re.sub(data_string, 
			',\n    "ruleset_type": "SQUARE",\n    "ruleset_description"')
		data_string = rules_re.sub(data_string, '"rules":')
		data_string = indexes_re.sub(data_string, '"part_indexes": [0, ', true)
		data_string = rot_re.sub(data_string, '"part_rotations": [0, ', true)
		data_string = flip_x_re.sub(data_string, '"part_flip_x": [false, ', true)
		data_string = flip_y_re.sub(data_string, '"part_flip_y": [false, ', true)
		file.store_string(data_string)
		file.close()
	hide()
