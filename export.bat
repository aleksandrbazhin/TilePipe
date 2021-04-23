::magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

set GODOT33=Godot_v3.3-stable_win64.exe
set GODOT323=Godot_v3.2.3-stable_win64.exe
set EXPORT_PATH=../godot_export/TilePipe
set WIN_EXPORT_PATH=%EXPORT_PATH:/=\%

ROBOCOPY generation_data %EXPORT_PATH%/examples *.png

:: windows
%GODOT33% --export "Windows Desktop" %EXPORT_PATH%/win/TilePipe.exe --no-window
7z a -r -tzip %EXPORT_PATH%/TilePipe_win64.zip %EXPORT_PATH%/win/* %EXPORT_PATH%/examples

:: linux
%GODOT33% --export "Linux/X11" %EXPORT_PATH%/linux/TilePipe.x86_64 --no-window
7z a -r -tzip %EXPORT_PATH%/TilePipe_linux.zip %EXPORT_PATH%/linux/* %EXPORT_PATH%/examples

:: mac
%GODOT323% --export "Mac OSX" %EXPORT_PATH%/mac/TilePipe_mac.zip --no-window
7z a -r -tzip %EXPORT_PATH%/mac/TilePipe_mac.zip %EXPORT_PATH%/examples
ROBOCOPY %EXPORT_PATH%/mac %EXPORT_PATH% TilePipe_mac.zip

del %WIN_EXPORT_PATH%\examples /Q

