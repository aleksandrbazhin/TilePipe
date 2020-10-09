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

- Save image or image+resourse

  