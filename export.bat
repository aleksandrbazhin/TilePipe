::magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico
::magick convert mac_icon.png -define icon:auto-resize=1024,512,256,128,64,48,32,16 icon.ico

set GODOT=Godot_v3.3-stable_win64.exe
set EXPORT_PATH=../godot_export/TilePipe
set WIN_EXPORT_PATH=%EXPORT_PATH:/=\%

::set EXAMPLES=generation_data

%GODOT% --export "Windows Desktop" %EXPORT_PATH%/win/TilePipe.exe --no-window
%GODOT% --export "Mac OSX" %EXPORT_PATH%/mac/TilePipe_mac.zip --no-window
%GODOT% --export "Linux/X11" %EXPORT_PATH%/linux/TilePipe.x86_64 --no-window

ROBOCOPY generation_data %EXPORT_PATH%/examples *.png

7z a -r -tzip %EXPORT_PATH%/TilePipe_win64.zip %EXPORT_PATH%/win/* %EXPORT_PATH%/examples
7z a -r -tzip %EXPORT_PATH%/TilePipe_mac.zip %EXPORT_PATH%/mac/* %EXPORT_PATH%/examples
7z a -r -tzip %EXPORT_PATH%/TilePipe_linux.zip %EXPORT_PATH%/linux/* %EXPORT_PATH%/examples

del %WIN_EXPORT_PATH%\examples /Q


::cd %EXPORT_PATH%
::tar -czvf TilePipe_win64.zip win
::cd ../../tilepipe

::cd %EXPORT_PATH%
::rcedit "TilePipe.exe" --set-icon "%EXPORT_PATH%/icon.ico"
::cd ../../tilepipe