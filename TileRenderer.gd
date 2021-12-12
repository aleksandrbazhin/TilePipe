extends Node

class_name TileRenderer

signal overlay_tiles_ready()
signal corner_tiles_ready()

func start_render_overlay_tiles():
	emit_signal("overlay_tiles_ready")

func start_render_corner_tiles():
	emit_signal("corner_tiles_ready")
