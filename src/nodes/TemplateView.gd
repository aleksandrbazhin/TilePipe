class_name TemplateView
extends VBoxContainer


var current_template_path := ""

onready var tile_name := $HBoxContainer/TileNameLabel
onready var template_texture_rect := $ScrollContainer/MarginContainer/TextureRect
onready var template_option: OptionButton = $HBoxContainer/TemplateFileName


func load_data(tile: TPTile):
	if tile == null:
		return
	tile_name.text = tile.tile_file_name
	current_template_path = tile.template_path
	populate_template_option()
	if current_template_path.empty():
		clear()
		return
	template_texture_rect.texture = tile.loaded_template
	label_bitmasks(tile)


func clear():
	clear_masks()
	template_texture_rect.texture = null


func clear_masks():
	for label in template_texture_rect.get_children():
		label.queue_free()


func label_bitmasks(tile: TPTile):
	clear_masks()
	var frame: TPTileFrame = tile.frames[0]
	for mask in frame.result_subtiles_by_bitmask.keys():
		for result_tile in frame.result_subtiles_by_bitmask[mask]:
			label_tile(result_tile)


func label_tile(generated_tile: GeneratedSubTile):
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


func _on_TemplateDialogButton_pressed():
	$AddTemplateFileDialog.popup_centered()


func _on_AddTemplateFileDialog_about_to_show():
	State.popup_started($AddTemplateFileDialog)


func _on_AddTemplateFileDialog_popup_hide():
	State.popup_ended()


func _on_AddTemplateFileDialog_file_selected(path: String):
	if not Helpers.ensure_directory_exists(State.current_dir, Const.TEMPLATE_DIR):
		State.report_error("Error: Creating directory \"/%s/\" error" % Const.TEMPLATE_DIR)
		return
	var new_template_path := State.current_dir + "/" + Const.TEMPLATE_DIR + "/" + path.get_file()
	var dir := Directory.new()
	var error := dir.copy(path, new_template_path)
	if error != OK:
		State.report_error("Error: Copy file error number %d." % error)
		return
	current_template_path = new_template_path
	populate_template_option()
	State.update_tile_param(TPTile.PARAM_TEMPLATE, current_template_path)
	load_data(State.get_current_tile())


func _on_TemplateFileName_item_selected(index: int):
	current_template_path = template_option.get_item_metadata(index)
	State.update_tile_param(TPTile.PARAM_TEMPLATE, current_template_path)
	if current_template_path.empty():
		clear()
		return
	load_data(State.get_current_tile())


func populate_template_option():
	var search_path: String = State.current_dir + "/" + Const.TEMPLATE_DIR
	var scan_func: FuncRef = funcref(Helpers, "scan_for_templates_in_dir")
	Helpers.populate_project_file_option(template_option, search_path, 
		scan_func, current_template_path)

