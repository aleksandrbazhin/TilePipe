extends VBoxContainer

class_name TemplateView

signal file_dialog_started()
signal file_dialog_ended()
signal report_error(text)
signal tile_template_changed(path)

var current_template_path := ""

onready var tile_name := $HBoxContainer/TileNameLabel
onready var template_texture_rect := $ScrollContainer/MarginContainer/TextureRect
onready var template_option: OptionButton = $HBoxContainer/TemplateFileName


func load_data(tile: TileInTree):
	tile_name.text = tile.tile_file_name
	current_template_path = tile.template_path
	populate_ruleset_options()
	if tile.template_path != "":
		template_texture_rect.texture = tile.loaded_template
		label_bitmasks(tile)


func label_bitmasks(tile: TileInTree):
	for label in template_texture_rect.get_children():
		label.queue_free()
	for mask in tile.result_tiles_by_bitmask.keys():
		for result_tile in tile.result_tiles_by_bitmask[mask]:
			label_tile(result_tile)


func label_tile(generated_tile: GeneratedTile):
	var label_offset := Vector2(0, 9)
	var translated_mask_position := generated_tile.position_in_template * Const.TEMPLATE_TILE_SIZE
	var mask_text_label := Label.new()
	mask_text_label.align = Label.ALIGN_CENTER
	mask_text_label.rect_size.x = Const.TEMPLATE_TILE_SIZE
	mask_text_label.add_color_override("font_color", Color.black)
	mask_text_label.add_font_override("font", preload("res://assets/styles/subscribe_font.tres"))
#		mask_text_label.rect_scale = Vector2(scale, scale)
	mask_text_label.text = str(generated_tile.bitmask)
	mask_text_label.rect_position = translated_mask_position + label_offset
	template_texture_rect.add_child(mask_text_label)


func populate_ruleset_options():
	template_option.clear()
	var templates_found := scan_for_templates_in_dir(Const.current_dir + "/" + Const.TEMPLATE_DIR)
	var index := 0
	for template_path in templates_found:
#		if is_file_a_ruleset(ruleset_path):
		template_option.add_item(template_path.get_file())
		template_option.set_item_metadata(index, template_path)
		if template_path == current_template_path:
			template_option.selected = index
		index += 1


func scan_for_templates_in_dir(path: String) -> PoolStringArray:
	var files := PoolStringArray([])
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "png":
			files.append(path + "/" + file)
	dir.list_dir_end()
	return files


func _on_TemplateFileName_item_selected(index: int):
	current_template_path = template_option.get_item_metadata(index)
	emit_signal("tile_template_changed", current_template_path)


func _on_TemplateDialogButton_pressed():
	$AddTemplateFileDialog.popup_centered()


func _on_AddTemplateFileDialog_about_to_show():
	emit_signal("file_dialog_started")


func _on_AddTemplateFileDialog_popup_hide():
	emit_signal("file_dialog_ended")


func _on_AddTemplateFileDialog_file_selected(path: String):
	if not Helpers.ensure_directory_exists(Const.current_dir, Const.TEMPLATE_DIR):
		emit_signal("report_error", "Error: Creating directory \"/%s/\" error" % Const.TEMPLATE_DIR)
		return
	var new_template_path := Const.current_dir + "/" + Const.TEMPLATE_DIR + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_template_path)
	if error == OK:
		current_template_path = new_template_path
		populate_ruleset_options()
		emit_signal("tile_template_changed", current_template_path)
	else:
		emit_signal("report_error", "Error: Copy file error number %d." % error)

