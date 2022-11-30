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
GITHUB_USER = "aleksandrbazhin"

_BASE_PARAMS = {"godot": GODOT, "godot_params": "--no-window --path . --export",  "path": EXPORT_PATH, "build_path": "", 
    "app_name": APP_NAME, "binary": "", "version": VERSION, "platform": "", "upload_suffix": "_win64"}

WIN_PARAMS = _BASE_PARAMS.copy()
WIN_PARAMS["build_path"] = f"{EXPORT_PATH}/win"
WIN_PARAMS["binary"] = f"{APP_NAME}.exe"
WIN_PARAMS["platform"] = "Windows Desktop"
WIN_PARAMS["upload_suffix"] = "_win64"

LINUX_PARAMS = _BASE_PARAMS.copy()
LINUX_PARAMS["build_path"] = f"{EXPORT_PATH}/linux"
LINUX_PARAMS["binary"] = f"{APP_NAME}.x86_64"
LINUX_PARAMS["platform"] = "Linux/X11"
LINUX_PARAMS["upload_suffix"] = "_linux"

MAC_PARAMS = _BASE_PARAMS.copy()
MAC_PARAMS["build_path"] = f"{EXPORT_PATH}/mac"
MAC_PARAMS["binary"] = f"{APP_NAME}._mac.zip"
MAC_PARAMS["platform"] = "Mac OSX"
MAC_PARAMS["upload_suffix"] = "_mac"


def update_godot_export_templates():
    export_config = configparser.ConfigParser()
    export_config.read("export_presets.cfg")
    PRESETS = [
        {"name": "preset.0", "export_path": f"{WIN_PARAMS['build_path']}/{WIN_PARAMS['binary']}"}, 
        {"name": "preset.2", "export_path": f"{LINUX_PARAMS['build_path']}/{LINUX_PARAMS['binary']}"},
        {"name": "preset.1", "export_path": f"{MAC_PARAMS['build_path']}/{MAC_PARAMS['binary']}"},
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
    os.system('butler push %(build_path)s/ aleksandrbazhin/TilePipe2:"%(platform)s" --userversion %(version)s' % params)


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

    print("\n____________________TilePipe______________________\nCreating a github release")
    import github_release
    github_release.create_git_tag(VERSION)
    github_release.push_git_tag()
    github_release.upload_github_release(GITHUB_USER, VERSION)

    print("____________________EXPORT FINISHED______________________\n")
