#::magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

import os
import shutil
from pathlib import Path
import configparser

GODOT33 = "Godot_v3.3-stable_win64.exe"
GODOT323 = "Godot_v3.2.3-stable_win64.exe"
EXPORT_PATH = "../godot_export/TilePipe"
WIN_BUILD_PATH = '%s/win' % EXPORT_PATH
LINUX_BUILD_PATH = '%s/linux' % EXPORT_PATH
MAC_BUILD_PATH = '%s/mac' % EXPORT_PATH

override_config = configparser.ConfigParser()
override_config.read("override.cfg")
VERSION = override_config['application']['config/version'].replace('"', '')

APP_NAME = 'TilePipe_v.%s' % VERSION

WIN_PARAMS = {"godot": GODOT33, "path": EXPORT_PATH, "build_path": WIN_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.exe" % APP_NAME}
LINUX_PARAMS = {"godot": GODOT33, "path": EXPORT_PATH, "build_path": LINUX_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.x86_64" % APP_NAME}
MAC_PARAMS = {"godot": GODOT323, "path": EXPORT_PATH, "build_path": MAC_BUILD_PATH, "app_name": APP_NAME, "binary": "%s_mac.zip" % APP_NAME}

# update godot export templates
def update_godot_export_templates():
    export_config = configparser.ConfigParser()
    export_config.read("export_presets.cfg")

    PRESETS = [{"name": "preset.0", "export_path": WIN_PARAMS["build_path"] + "/" + WIN_PARAMS["binary"]}, 
               {"name": "preset.1", "export_path": MAC_PARAMS["build_path"] + "/" + MAC_PARAMS["binary"]},
               {"name": "preset.2", "export_path": LINUX_PARAMS["build_path"] + "/" + LINUX_PARAMS["binary"]}]
    for preset in PRESETS:
        export_config[preset["name"]]["export_path"] = '"%s"' % preset["export_path"]
        export_config[preset["name"] + ".options"]["application/version"] = '"%s"' % VERSION
        export_config[preset["name"] + ".options"]["application/short_version"] = '"%s"' % VERSION
        
    with open('export_presets.cfg', 'w') as configfile:
        export_config.write(configfile, space_around_delimiters=False)

update_godot_export_templates()

Path(EXPORT_PATH).mkdir(parents=True, exist_ok=True)
Path(WIN_BUILD_PATH).mkdir(parents=True, exist_ok=True)
Path(LINUX_BUILD_PATH).mkdir(parents=True, exist_ok=True)
Path(MAC_BUILD_PATH).mkdir(parents=True, exist_ok=True)

os.system("ROBOCOPY  generation_data %s/examples *.png" % EXPORT_PATH)

# windows
os.system('%(godot)s --export "Windows Desktop" %(build_path)s/%(binary)s --no-window' % WIN_PARAMS)
os.system('7z a -r -tzip %(path)s/%(app_name)s_win64.zip %(build_path)s/* %(path)s/examples' % WIN_PARAMS)

# linux
os.system('%(godot)s --export "Linux/X11" %(build_path)s/%(binary)s --no-window' % LINUX_PARAMS)
os.system('7z a -r -tzip %(path)s/%(app_name)s_linux.zip %(build_path)s/* %(path)s/examples' % LINUX_PARAMS)

# mac
os.system('%(godot)s --export "Mac OSX" %(build_path)s/%(binary)s --no-window' % MAC_PARAMS)
os.system('7z a -r -tzip %(build_path)s/%(binary)s %(path)s/examples' % MAC_PARAMS)
os.system('ROBOCOPY %(build_path)s %(path)s %(binary)s' % MAC_PARAMS)

shutil.rmtree("%s/examples" % EXPORT_PATH)