extends Control

onready var text_node = $HBoxContainer/PresetContainer/RichTextLabel
onready var render_node: ViewportContainer = $HBoxContainer/TemplateContainer/ScrollContainer/ViewportContainer

const CORNER_MASK_CHECKS := [2, 10, 34, 42, 170]

# compute all alternative 255 masks for 47 blob mask (with insignificant corner neighbours)
func find_mask_alternatives(mask: int) -> Array:
	var alternatives := [] 
	for check_mask in CORNER_MASK_CHECKS:
		for rotation in range(0, 8, 2):
			var neighbour_mask = Helpers.rotate_check_mask(check_mask, rotation)
			if mask & neighbour_mask != 0: # neighbour mask already in the mask
				continue
			var mask_alternative: int = mask | neighbour_mask
			if mask == mask_alternative or alternatives.has(mask_alternative):
				continue
			var skip := false
			for corner_bit in [2, 8, 32, 128]: # separate btis in neighbour mask
				if neighbour_mask & corner_bit == 0: # neighbour_mask does not has this corner
					continue
				var cw_corner_neighbour: int = Helpers.rotate_check_mask(corner_bit, 1)
				var ccw_corner_neighbour: int = Helpers.rotate_check_mask(corner_bit, 7)
				# mask has both corner neighbours for corner_bit
				if mask & cw_corner_neighbour != 0 and mask & ccw_corner_neighbour != 0:
					skip = true
					break
			if not skip:
				alternatives.append(mask_alternative)
#
#

#	for neigbour_name in Const.TILE_MASK:
#		var is_diagonal = neigbour_name in ["TOP_RIGHT", "BOTTOM_RIGHT", "BOTTOM_LEFT", "TOP_LEFT"]
#		if is_diagonal:
#			var neighbour_bit: int = Const.TILE_MASK[neigbour_name]
#			if mask & neighbour_bit != 0: # neighbour already in the mask
#				continue
#			var cw_neighbour: int = Helpers.rotate_mask_cw(neighbour_bit)
#			var ccw_neighbour: int = Helpers.rotate_mask_ccw(neighbour_bit)
#			if mask & cw_neighbour != 0 and mask & ccw_neighbour != 0: 
#				continue
#			alternatives.append(mask | neighbour_bit)
#
#
			
	return alternatives
#

func _on_PresetButton_pressed():
	var reference_generation_data := GenerationData.new("res://generation_data/overlay_13.json")
	for tile_data in reference_generation_data.data["data"]:
		var mask_variants: Array = tile_data["mask_variants"]
		var base_mask: int = mask_variants[0]
		mask_variants.append_array(find_mask_alternatives(base_mask))
		
		
		for i in range(mask_variants.size() - 1):
			tile_data["variant_rotations"].append(0)


	text_node.text = JSON.print(reference_generation_data.data, "\t")


func _on_TemplateButton_pressed():
	render_node.draw_data()


func _on_SaveButton_pressed():
	$TemplateFileDialog.popup_centered()
	

func _on_FileDialog_file_selected(path):
	var image: Image = render_node.get_texture().get_data()
	image.flip_y()
	image.save_png(path)


func _on_PresetFileDialog_file_selected(path):
	var data_file = File.new()
	data_file.open(path, File.WRITE)
	data_file.store_string(text_node.text)
	data_file.close()


func _on_SavePresetButton_pressed():
	$PresetFileDialog.popup_centered()
