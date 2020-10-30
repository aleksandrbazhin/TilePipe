# Godot tilesheet generator

### ! The project is in "barely working" state and is not likely to ever leave it

## Why?

To automate tile texture creation for autotiles 3x3

To create those 47 and 255 tile tilesheets not by hand

## How

- Upload template to generate autotiles

  - Size must match setting, default - 64 x 64
  - White color is considered empty, any other - full
  - One pixel color 10 pixels away from sides is tested
- Choose an image of 5 tile slices, it will be upscaled or downscaled
- Save image or image+resource





## Generation templates

{
"type": "overlay",
"example": "overlay_7_pixelart.png",
"name": "input_overlay_7",
"min_size": {
	"x": 7,
	"y": 1
},
"data": [
	{
		"mask_variants": [64, 4],
		"variant_rotations": [0, 0],

​		"variant_flips": [0, 1], - flip variant instead rotation

​		"generate_piece_indexes":   [2, 3, 2, 3, 2, 2, 0, 2],
​		"generate_piece_rotations": [0, 0, 1, 1, 2, 2, 0, 0],
​		"generate_use _flipped": [0, 0, 0, 0, 0, 0, 0, 0], - use flipped one instead of rotated, if not 0, takes the flipped by the rotation
​		"generate_overlap_vectors": [[0, 1], [1, 1], [1, 0], [1, 1], [0, 1], [0, 1], [0, 0], [0, 1]], - the vector in which direction to overlap, (0, 0) - leave all bg, (1, 1) - remove_all_bg, like corner, (-1, -1) - leave bg like internal corner, (1, 0) - x direction, (-1, 0) - y direction
​	},