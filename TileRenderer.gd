extends Node

class_name TileRenderer

signal tiles_ready()


const RENDER_POOL_SIZE = 64


var is_rendering = false
var render_pool := []

var input_image: Image
var template
var ruleset: GenerationData
var tile_size := Vector2.ZERO
var overlay_amount
var merge_amount
var random_seed
var smoothing
var resize_factor
var ready = false
var last_mask := 0
#var last_rendered_random_index := 0

# tiles[mask] = [random_variant1, random_variant2, ...]
var tiles := {} 

func _ready():
	VisualServer.connect("frame_post_draw", self, "on_render")
	init_render_pool()
	ready = true



func init_render_pool():
	print(ready)
	for _i in range(RENDER_POOL_SIZE):
		var viewport := Viewport.new()
		render_pool.append(viewport)
		viewport.transparent_bg = true
		viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		var texture_rect := TextureRect.new()
		viewport.add_child(texture_rect, true)
		add_child(viewport)
		

func create_tile(mask: int) -> Texture:
#	print(ruleset.get_mask_data(mask))
	
#	last_rendered_random_index
	
	var tile := Image.new()
	tile.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
	tile.blit_rect(input_image, Rect2(0, 0, tile_size.x, tile_size.y), Vector2.ZERO)
	var itex := ImageTexture.new()
	itex.create_from_image(tile)
	return itex


func start_render(new_ruleset: GenerationData, new_tile_size: Vector2, new_input: Image, template_bitmasks: Dictionary):
#	print(ready)
#	tiles.clear()
	tiles = template_bitmasks
#	print(tiles)
	ruleset = new_ruleset
	tile_size = new_tile_size
	input_image = new_input
	last_mask = tiles.keys()[0]
	for viewport in render_pool:
		viewport.size = tile_size
		viewport.get_node("TextureRect").rect_size = tile_size
#		viewport.
	render_next_batch()
	is_rendering = true
	


func render_next_batch():
#	assert(batch.size() == render_pool.size())
#	var max_mask: int = tiles.keys().max()
#	var index := max_mask + 1
#	var index = 0
	for viewport in render_pool:
#		var mask = get_next_mask()
#		last_mask = mask

		var tile: GeneratedTile = get_next_tile()
#		if tile != null:
		
		
		if tile != null:
			last_mask = tile.mask
#			print(tile.mask)
			tile.is_rendering = true
#			var tile_texture = 
			viewport.get_node("TextureRect").texture = create_tile(tile.mask)
#			viewport.set_meta("mask_value", index)
			viewport.set_meta("tile", tile)
		else:
			viewport.remove_meta("tile")
		
#			viewport.set_meta("mask_value", -1)
#		index += 1

	
#		viewport.set_meta("random_index", 0)

func get_next_tile() -> GeneratedTile:
	for tile in tiles[last_mask]:
		if tile.image == null and not tile.is_rendering:
			return tile
	var mask_index := tiles.keys().find(last_mask)
	if mask_index == tiles.size() - 1:
		return null
	var next_mask = tiles.keys()[mask_index + 1]
	return tiles[next_mask][0]


func capture_rendered_batch():
#	var starting_index := 
#	var current_index := tiles.size()
	for viewport in render_pool:
		var tile_texture: ViewportTexture = viewport.get_texture()
		var image := Image.new()
		image.create(int(tile_size.x), int(tile_size.y), false, Image.FORMAT_RGBA8)
		image.blit_rect(
			tile_texture.get_data(),
			Rect2(Vector2.ZERO, tile_size), 
			Vector2.ZERO)
#		if resize_factor != 1.0:
#			var interpolation: int = Image.INTERPOLATE_NEAREST if not smoothing_check.pressed else Image.INTERPOLATE_TRILINEAR
#			image.resize(int(size.x * resize_factor), int(size.y * resize_factor), interpolation)
#		print(viewport.has_meta("mask_value"))
		if viewport.has_meta("tile") :
			var tile: GeneratedTile = viewport.get_meta("tile")
#			var mask_value := tile.mask
			tile.image = image
#			if mask_value == -1: 
#				break
#			if not tiles.has(mask_value):
#				tiles[mask_value] = []
#			tiles[mask_value].append(image)

		
func get_template_random_variants(_mask: int):
	return 1





func on_render():
	if is_rendering:
#		var total_tiles: int = 256#ruleset.data["data"].size()
#		print(tiles.size() , "  ", total_tiles)
		capture_rendered_batch()
		emit_signal("tiles_ready")
#		var last_mask: int = int(ruleset.get_ruleset()[-1]["mask_variants"][-1])
#		print("last_mask: ", last_mask)
#		if tiles.has(last_mask) and tiles[last_mask].size() == get_template_random_variants(last_mask):
##		if tiles.size() < total_tiles:
#			render_next_batch()
#		else:
#			is_rendering = false
#			emit_signal("tiles_ready")


	
	


