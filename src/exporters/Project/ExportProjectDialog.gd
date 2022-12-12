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
var export_tile_separation: int = 0
var rendered_tiles_refs := {}


onready var result_texture := $MarginContainer/VBoxContainer/HBoxContainerMain/ProjectResultTextureRect
onready var progress_bar := $ProgressBar
onready var texture_file_dialog := $TextureFileDialog
onready var godot3_file_dialog := $Godot3FileDialog
onready var path_edit_texture := $MarginContainer/VBoxContainer/HBoxContainerTexture/LineEdit
onready var godot3_block := $MarginContainer/VBoxContainer/HBoxContainerGodot
onready var path_edit_godot := $MarginContainer/VBoxContainer/HBoxContainerGodot/GodotPath
onready var export_type_option := $MarginContainer/VBoxContainer/HBoxContainerTexture/OptionButton
onready var tile_settings_container := $MarginContainer/VBoxContainer/HBoxContainerMain/ScrollContainer/VBoxSettings/VBoxContainerTiles
onready var tile_separation_spinbox := $MarginContainer/VBoxContainer/HBoxContainerMain/ScrollContainer/VBoxSettings/HBoxContainerTileSeparation/SeparationSpinBox


func setup(tiles: Array):
	rendered_tiles_refs = {}
	for tile_ui in tile_settings_container.get_children():
		tile_ui.free()
	for tile_index in tiles.size():
		var tile: TPTile = tiles[tile_index]
		rendered_tiles_refs[tile_index] = weakref(tile)
		var tile_label := Label.new()
		tile_label.text = tile.tile_file_name.get_basename()
		tile_settings_container.add_child(tile_label)

	tile_separation_spinbox.set_value_quietly(export_tile_separation)
	match export_type:
		Const.EXPORT_PROJECT.SINGLE_TEXTURE:
			export_type_option.selected = Const.EXPORT_PROJECT.SINGLE_TEXTURE
			godot3_block.hide()
		Const.EXPORT_PROJECT.GODOT3:
			export_type_option.selected = Const.EXPORT_PROJECT.GODOT3
			godot3_block.show()
	path_edit_texture.text = export_path_texture
	path_edit_godot.text = export_path_godot
	render_all()


func render_all():
	tile_offsets = {}
	total_size = Vector2.ZERO
	frame_number = 0
	subtile_number = 0

	for tile_index in rendered_tiles_refs.keys():
		var tile_ref: WeakRef = rendered_tiles_refs[tile_index]
		if tile_ref == null or not tile_ref.get_ref() is TPTile:
			continue
		var tile: TPTile =  tile_ref.get_ref()
		if tile == null or not tile.is_able_to_render():
			continue
		if tile.frames.empty():
			continue
		var tile_full_size := tile.get_full_tile_rendered_size()
		if tile_full_size == Vector2.ZERO:
			continue
		frame_number += tile.frames.size()
		subtile_number += tile.frames[0].get_subtile_count() * tile.frames.size()
		tile_offsets[tile_index] = Vector2(0, total_size.y + export_tile_separation)
		total_size = Vector2(
			max(total_size.x, tile_full_size.x), 
			tile_offsets[tile_index].y + tile_full_size.y)
	result_texture.reset(total_size)
	update_progress(0)
	render_subtile_count = 0


	for tile_index in rendered_tiles_refs.keys():
		var tile_ref: WeakRef = rendered_tiles_refs[tile_index]
		if tile_ref == null or not tile_ref.get_ref() is TPTile:
			continue
		var tile: TPTile =  tile_ref.get_ref()
		if tile == null or not tile.is_able_to_render():
			continue
		for frame_index in tile.frames.size():
			var renderer := TileRenderer.new()
			add_child(renderer)
			renderer.connect("subtiles_ready", self, "on_frame_render", [tile, tile_index])
			renderer.start_render(tile, frame_index)
			self.connect("popup_hide", renderer, "free")
		yield(VisualServer, "frame_post_draw")


func on_frame_render(frame_index: int, tile: TPTile, tile_index: int):
	if frame_index == 0:
		tile.update_tree_icon()

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
		Const.EXPORT_PROJECT.SINGLE_TEXTURE:
			if export_image.save_png(export_path_texture) != OK:
				State.report_error("Error exporting image")
				return
		Const.EXPORT_PROJECT.GODOT3:
			if not GodotExporter.is_a_valid_resource_path(export_path_godot):
				State.report_error("Path is not in any Godot project. \nSelect path in an exisisting Godot project.")
				return
			if not GodotExporter.is_a_valid_texture_path(export_path_texture, export_path_godot):
				State.report_error("Texture must be in the same godot project as the tileset resource.")
				return
			if export_image.save_png(export_path_texture) != OK:
				State.report_error("Error exporting image")
				return
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
		if tile == null or not tile.is_able_to_render():
			continue
		if tile.frames.empty():
			continue
		
		tileset.create_tile(tile_index)
		tileset.tile_set_name(tile_index, tile.tile_file_name.get_basename())
		tileset.autotile_set_size(tile_index, tile.get_output_tile_size())
		tileset.tile_set_tile_mode(tile_index, TileSet.AUTO_TILE)
		tileset.tile_set_texture_offset(tile_index, tile.tex_offset)
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
		State.report_error("Error saving tileset to a file.")
		return false
	if not finalize_godot_export_file():
		return false
	return true


func finalize_godot_export_file() -> bool:
	var file := File.new()
	if file.open(export_path_godot, File.READ) != OK:
		State.report_error("Error saving tileset to a file (2).")
		return false
	var file_data := file.get_as_text()
	file.close()	
	var texture_rel_path := GodotExporter.project_export_relative_path(export_path_texture)
	var resource_regex := RegEx.new()
	resource_regex.compile('\\[resource\\]')
	file_data = resource_regex.sub(file_data, 
		'[ext_resource path="%s" ' % texture_rel_path +
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
		State.report_error("Error saving tileset to a file (3).")
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
			godot3_block.hide()
			emit_signal("settings_changed")
		Const.EXPORT_PROJECT.GODOT3:
			export_type = index
			path_edit_godot.text = export_path_godot
			godot3_block.show()
			emit_signal("settings_changed")


func _on_TextureFileDialog_file_selected(path):
	export_path_texture = path
	path_edit_texture.text = export_path_texture
	emit_signal("settings_changed")



func _on_Godot3FileDialog_file_selected(path):
	if not GodotExporter.is_a_valid_resource_path(path):
		State.report_error("Path is not in any Godot project. \nSelect path in an exisisting Godot project.")
		return
	export_path_godot = path
	path_edit_godot.text = export_path_godot
	emit_signal("settings_changed")


func _on_FileDialogButton_pressed():
	texture_file_dialog.current_path = export_path_texture
	texture_file_dialog.popup_centered()


func _on_GodotFileDialogButton_pressed():
	godot3_file_dialog.current_path = export_path_godot
	godot3_file_dialog.popup_centered()


func _on_SeparationSpinBox_value_changed_no_silence(value):
	export_tile_separation = int(value)
	emit_signal("settings_changed")
	render_all()
	
