#::magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

import os
import shutil
from pathlib import Path
import configparser


GODOT = "~/Public/Godot_v3.5-stable_x11.64"
EXPORT_PATH = "../build/TilePipe2"


override_config = configparser.ConfigParser()
override_config.read("override.cfg")
VERSION = override_config['application']['config/version'].replace('"', '')
APP_NAME = 'TilePipe2_v.%s' % VERSION
WIN_PARAMS = {"godot": GODOT, "godot_params": "--no-window --path . --export",  "path": EXPORT_PATH, "build_path": EXPORT_PATH + "/win", 
    "app_name": APP_NAME, "binary": "%s.exe" % APP_NAME, "version": VERSION, "platform": "Windows Desktop", "upload_suffix": "_win64"}
LINUX_PARAMS = {"godot": GODOT, "godot_params": "--no-window --path . --export", "path": EXPORT_PATH, "build_path": EXPORT_PATH + "/linux", 
    "app_name": APP_NAME, "binary": "%s.x86_64" % APP_NAME, "version": VERSION, "platform": "Linux/X11", "upload_suffix": "_linux"}
MAC_PARAMS = {"godot": GODOT, "godot_params": "--no-window --path . --export", "path": EXPORT_PATH, "build_path": EXPORT_PATH + "/mac", 
    "app_name": APP_NAME, "binary": "%s_mac.zip" % APP_NAME, "version": VERSION, "platform": "Mac OSX", "upload_suffix": "_mac"}


def update_godot_export_templates():
    export_config = configparser.ConfigParser()
    export_config.read("export_presets.cfg")
    PRESETS = [
                {"name": "preset.0", "export_path": WIN_PARAMS["build_path"] + "/" + WIN_PARAMS["binary"]}, 
                {"name": "preset.2", "export_path": LINUX_PARAMS["build_path"] + "/" + LINUX_PARAMS["binary"]},
                {"name": "preset.1", "export_path": MAC_PARAMS["build_path"] + "/" + MAC_PARAMS["binary"]},
            ]
    for preset in PRESETS:
        export_config[preset["name"]]["export_path"] = '"%s"' % preset["export_path"]
        export_config[preset["name"] + ".options"]["application/version"] = '"%s"' % VERSION
        export_config[preset["name"] + ".options"]["application/short_version"] = '"%s"' % VERSION
        export_config[preset["name"]]["exclude_filter"] = '"*.import"'
    # win specific params
    # ! to export icon from linux, rcedit must be set up in EditorSettings: Export/Windows
    export_config["preset.0.options"]["product/version"] = '"%s"' % VERSION
    export_config["preset.0.options"]["application/icon"] = '"res://assets/icon.ico"'
    export_config["preset.0.options"]["application/product_version"] = '"%s"' % VERSION
    export_config["preset.0.options"]["application/company_name"] = '"Aleksandr Bazhin"'
    export_config["preset.0.options"]["application/product_name"] = '"TilePipe2"'
    export_config["preset.0.options"]["application/file_description"] = '"Pipeline tool for tilesets"'
    # mac specific params
    export_config["preset.1.options"]["application/identifier"] = '"com.tilepipe2.utility"'
    export_config["preset.1.options"]["application/icon"] = '"res://assets/icon.icns"'
    export_config["preset.1.options"]["application/name"] = '"TilePipe2"'
    export_config["preset.1.options"]["application/info"] = '"Pipeline tool for tilesets"'
    with open('export_presets.cfg', 'w') as config_file:
        export_config.write(config_file, space_around_delimiters=False)


def build(params):
    Path(EXPORT_PATH).mkdir(parents=True, exist_ok=True)
    shutil.rmtree("%(build_path)s" % params, ignore_errors=True)
    Path("%(build_path)s" % params).mkdir(parents=True, exist_ok=True)
    os.system('%(godot)s %(godot_params)s "%(platform)s" %(build_path)s/%(binary)s' % params)
    shutil.copytree('examples', '%(build_path)s/examples' % params, dirs_exist_ok=True)


def upload_itch(params):
    # print('butler push %(build_path)s/ aleksandrbazhin/TilePipe2:%(platform)s --userversion %(version)s' % params)
    os.system('butler push %(build_path)s/ aleksandrbazhin/TilePipe2:"%(platform)s" --userversion %(version)s' % params)


def _upload_other(params):
    shutil.make_archive('%(path)s/uploads/%(app_name)s%(upload_suffix)s' % params, 'zip', '%(build_path)s' % params)
    # upload command here


if __name__ == "__main__":
        print("\n____________________TilePipe______________________\nBuilding\n")
        update_godot_export_templates()
        build(WIN_PARAMS)
        build(LINUX_PARAMS)
        build(MAC_PARAMS)

        print("\n____________________TilePipe______________________\nUploading build to itch.io")
        upload_itch(WIN_PARAMS)
        upload_itch(LINUX_PARAMS)
        upload_itch(MAC_PARAMS)
        

