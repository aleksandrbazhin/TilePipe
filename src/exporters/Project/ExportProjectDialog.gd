class_name ExportProjectDialog
extends WindowDialog


signal settings_changed()


var tile_number := 0
var frame_number := 0
var subtile_number := 0
var render_subtile_count := 0
var total_size := Vector2.ZERO
# dictionary {tile_index: Vector2, ...}
var tile_offsets: Dictionary = {}
var export_type: int = Const.EXPORT_PROJECT.SINGLE_TEXTURE
var export_path_texture: String = ""
var export_path_godot: String = ""
var rendered_tiles_refs := {}


onready var result_texture := $MarginContainer/VBoxContainer/ProjectResultTextureRect
onready var progress_bar := $ProgressBar
onready var texture_file_dialog := $TextureFileDialog
onready var godot3_file_dialog := $Godot3FileDialog
onready var path_edit_texture := $MarginContainer/VBoxContainer/HBoxContainer2/LineEdit
onready var godot_block := $MarginContainer/VBoxContainer/HBoxContainerGodot
onready var path_edit_godot := $MarginContainer/VBoxContainer/HBoxContainerGodot/GodotPath
onready var export_type_option := $MarginContainer/VBoxContainer/HBoxContainer2/OptionButton


func setup(tiles: Array):
	tile_offsets = {}
	rendered_tiles_refs = {}
	total_size = Vector2.ZERO
	tile_number = tiles.size()
	frame_number = 0
	subtile_number = 0
	for tile_index in tiles.size():
		var tile: TPTile = tiles[tile_index]
		if not tile.is_able_to_render():
			continue
		if tile.frames.empty():
			continue
#		var frame_size := tile.get_rendered_frame_size()
		var tile_full_size := tile.get_full_tile_rendered_size()
#		print(tile.tile_file_name, " ", frame_size)
		if tile_full_size == Vector2.ZERO:
			continue
		frame_number += tile.frames.size()
		subtile_number += tile.frames[0].get_subtile_count() * tile.frames.size()

		tile_offsets[tile_index] = Vector2(0, total_size.y)
		total_size = Vector2(
			max(total_size.x, tile_full_size.x), 
			total_size.y + tile_full_size.y)
		rendered_tiles_refs[tile_index] = weakref(tile)
	result_texture.reset(total_size)
	update_progress(0)
	render_subtile_count = 0
	match export_type:
		Const.EXPORT_PROJECT.SINGLE_TEXTURE:
			export_type_option.selected = Const.EXPORT_PROJECT.SINGLE_TEXTURE
			godot_block.hide()
		Const.EXPORT_PROJECT.GODOT3:
			export_type_option.selected = Const.EXPORT_PROJECT.GODOT3
			godot_block.show()
	path_edit_texture.text = export_path_texture
	path_edit_godot.text = export_path_godot


func on_frame_render(frame_index: int, tile: TPTile, tile_index: int):
	add_tile_frame(tile, frame_index, tile_index)
	if subtile_number != 0:
		render_subtile_count += tile.frames[0].get_subtile_count()
# warning-ignore:integer_division
		var progress: int = 100 * render_subtile_count / subtile_number
		update_progress(progress)


func update_progress(progress: int):
	progress_bar.value = progress
#	State.emit_signal("render_progress", progress)


func add_tile_frame(tile: TPTile, frame_index: int, tile_index: int):
	var frame_size := tile.get_rendered_frame_size()
	var frame: TPTileFrame = tile.frames[frame_index]
	frame.merge_result_from_subtiles(tile.template_size, 
		tile.get_output_tile_size(), tile.subtile_spacing)
	var frame_offset_y = tile_offsets[tile_index].y + \
		frame_index * (frame_size.y + tile.subtile_spacing.y)
	result_texture.add_texture(frame.result_texture, Vector2(0, frame_offset_y))


func _on_ExportProjectDialog_about_to_show():
	State.popup_started(self)


func _on_ExportProjectDialog_popup_hide():
	State.popup_ended()


func _on_ButtonCancel_pressed():
	hide()


# TODO:
# 3 - check size
func _on_ButtonOk_pressed():
	if progress_bar.value < 100:
		return
	if result_texture.texture == null:
		State.report_error("No texture")
		return
	var export_image: Image = result_texture.texture.get_data()
	if export_image == null:
		State.report_error("No texture")
		return
	if export_path_texture.empty():
		return
	match export_type:
		Const.EXPORT_PROJECT.SINGLE_TEXTURE, Const.EXPORT_PROJECT.GODOT3:
			if export_image.save_png(export_path_texture) != OK:
				State.report_error("Error exporting image")
				return
			continue
		Const.EXPORT_PROJECT.GODOT3:
			if not export_to_godot3_tileset():
				return
	hide()


#TODO: 
#1 check if texture in the same godot project path with the tileset
#2 get texture relative path


func export_to_godot3_tileset() -> bool:
	var tileset := TileSet.new()
	for tile_index in rendered_tiles_refs.keys():
		var tile_ref: WeakRef = rendered_tiles_refs[tile_index]
		if tile_ref == null or not tile_ref.get_ref() is TPTile:
			continue
		var tile: TPTile = tile_ref.get_ref()
		tileset.create_tile(tile_index)
		tileset.tile_set_name(tile_index, tile.tile_file_name.get_basename())
		tileset.autotile_set_size(tile_index, tile.get_output_tile_size())
		tileset.tile_set_tile_mode(tile_index, TileSet.AUTO_TILE)
		tileset.tile_set_texture_offset(tile_index, tile.tex_offset)
		if tile.frames.empty():
			continue
		var bitmask_type := Helpers.assume_godot_autotile_type(tile.frames[0].result_subtiles_by_bitmask)
		tileset.autotile_set_bitmask_mode(tile_index, bitmask_type)
		tileset.autotile_set_spacing(tile_index, int(tile.subtile_spacing.x))
		var frame_size := tile.get_rendered_frame_size()
		var tile_size := Vector2(frame_size.x, frame_size.y * tile.frames.size())
		tileset.tile_set_region(tile_index, Rect2(tile_offsets[tile_index], tile_size))
		for frame_index in tile.frames.size():
			var frame: TPTileFrame = tile.frames[frame_index]
			for bitmask in frame.result_subtiles_by_bitmask:
				for subtile in frame.result_subtiles_by_bitmask[bitmask]:
					var subtile_pos: Vector2 = subtile.position_in_template
					subtile_pos.y += tile.template_size.y * frame_index
					tileset.autotile_set_bitmask(
						tile_index, 
						subtile_pos, 
						Helpers.convert_bitmask_to_godot(bitmask)
					)
	if ResourceSaver.save(export_path_godot, tileset) != OK:
		State.report_error("Error 1 saving tileset")
		return false

	if not finalize_godot_export_file():
		return false
	
	return true


func finalize_godot_export_file() -> bool:
	var file := File.new()
	if file.open(export_path_godot, File.READ) != OK:
		State.report_error("Error 2 saving tileset")
		return false
	var file_data := file.get_as_text()
	file.close()
	
#	var texture_rel_path: String = export_path_texture
	var texture_rel_path: String = "all.png"

	var resource_regex := RegEx.new()
	resource_regex.compile('\\[resource\\]')
	file_data = resource_regex.sub(file_data, 
		'[ext_resource path="res://%s" ' % texture_rel_path +
		'type="Texture" id=1]\n\n[resource]')
	var tile_name_regex := RegEx.new()
	tile_name_regex.compile('(\\d+)/name\\s*=\\s*".+"\\n')
	var reg_result = tile_name_regex.search(file_data, 0)
	while reg_result != null:
		var end: int = reg_result.get_end()
		var tile_id := int(reg_result.strings[1])
		file_data = file_data.insert(end, "%d/texture = ExtResource( 1 )\n" % tile_id)
		reg_result = tile_name_regex.search(file_data, end)
	if file.open(export_path_godot, File.WRITE) != OK:
		State.report_error("Error 2 saving tileset")
		return false
	file.store_string(file_data)
	file.close()
	return true


func _input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if texture_file_dialog.visible:
			texture_file_dialog.hide()
			get_tree().set_input_as_handled()
		elif godot3_file_dialog.visible:
			godot3_file_dialog.hide()
			get_tree().set_input_as_handled()


func _on_OptionButton_item_selected(index: int):
	match index:
		Const.EXPORT_PROJECT.SINGLE_TEXTURE:
			export_type = index
			path_edit_texture.text = export_path_texture
			godot_block.hide()
			emit_signal("settings_changed")
		Const.EXPORT_PROJECT.GODOT3:
			export_type = index
			path_edit_godot.text = export_path_godot
			godot_block.show()
			emit_signal("settings_changed")


func _on_TextureFileDialog_file_selected(path):
	export_path_texture = path
	path_edit_texture.text = export_path_texture
	emit_signal("settings_changed")


#TODO: check if tileset in the godot project path
func _on_Godot3FileDialog_file_selected(path):
	export_path_godot = path
	path_edit_godot.text = export_path_godot
	emit_signal("settings_changed")


func _on_FileDialogButton_pressed():
	texture_file_dialog.current_path = export_path_texture
	texture_file_dialog.popup_centered()


func _on_GodotFileDialogButton_pressed():
	godot3_file_dialog.current_path = export_path_godot
	godot3_file_dialog.popup_centered()
	
