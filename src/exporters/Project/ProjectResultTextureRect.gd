extends TextureRect


func reset(size: Vector2):
	var result := Image.new()
	result.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
#	result.fill(Color("282d33"))w
	var itex := ImageTexture.new()
	itex.create_from_image(result)
	texture = itex
	$Label.text = str(size.x) + " x " + str(size.y) + " px"
	

func add_texture(frame_texture: Texture, frame_position: Vector2):
	var result = texture.get_data()
	result.blit_rect(frame_texture.get_data(), 
		Rect2(Vector2.ZERO, frame_texture.get_size()), 
		frame_position)
	var itex := ImageTexture.new()
	itex.create_from_image(result)
	texture = itex


#func combine_frames():
#	var result := Image.new()
#	result.create(1000, 1000, false, Image.FORMAT_RGBA8)
#	for i in result_frames.size():
#		var frame: Texture = result_frames[i]
#		var frame_position: Vector2 = result_frame_positions[i]
#		if frame is Texture:
#			print(frame.get_data().get_format())
#			result.blit_rect(frame.get_data(), 
#				Rect2(Vector2.ZERO, frame.get_size()), 
#				frame_position)
#			var itex := ImageTexture.new()
#			itex.create_from_image(result)
#			texture = itex
##			draw_texture_rect_region(
##				frame, 
##				Rect2(frame_position, frame.get_size()), 
##				Rect2(Vector2.ZERO, frame.get_size()))
#			print("draw to ", frame_position)
#		else:
#			print("fail")
