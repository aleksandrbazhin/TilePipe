:: magick convert icon.png -define icon:auto-resize=256,128,64,16,20,24,28,30,31,32,40,42,47,48,56,60,63,84 icon.ico
godot --export "Windows Desktop" ../godot_export/TilePipe.exe --no-window
godot --export "Mac OSX" ../godot_export/TilePipe_mac.zip --no-window
godot --export "Linux/X11" ../godot_export/TilePipe.x86_64 --no-window
::cd ../godot_export
::rcedit "TilePipe.exe" --set-icon "../tilepipe/icon.ico"
::cd ../tilepipe