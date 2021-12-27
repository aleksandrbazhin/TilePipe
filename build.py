#::magick convert icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico

import os
import shutil
from pathlib import Path
import configparser

GODOT = "Godot_v3.4.2-stable_win64.exe"
GODOT_FOR_MAC = "Godot_v3.2.3-stable_win64.exe"
EXPORT_PATH = "../godot_export/TilePipe"
WIN_BUILD_PATH = '%s/win' % EXPORT_PATH
LINUX_BUILD_PATH = '%s/linux' % EXPORT_PATH
MAC_BUILD_PATH = '%s/mac' % EXPORT_PATH

override_config = configparser.ConfigParser()
override_config.read("override.cfg")
VERSION = override_config['application']['config/version'].replace('"', '')

APP_NAME = 'TilePipe_v.%s' % VERSION

WIN_PARAMS = {"godot": GODOT, "godot_params": "--no-window --export",  "path": EXPORT_PATH, "build_path": WIN_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.exe" % APP_NAME, "version": VERSION}
LINUX_PARAMS = {"godot": GODOT, "godot_params": "--no-window --export", "path": EXPORT_PATH, "build_path": LINUX_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.x86_64" % APP_NAME, "version": VERSION}
MAC_PARAMS = {"godot": GODOT_FOR_MAC, "godot_params": "--no-window --export", "path": EXPORT_PATH, "build_path": MAC_BUILD_PATH, "app_name": APP_NAME, "binary": "%s_mac.zip" % APP_NAME, "version": VERSION}


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
        export_config[preset["name"]]["include_filter"] = '"generation_data/*"'
        export_config[preset["name"]]["exclude_filter"] = '"*.import"'
    # win params 
    export_config["preset.0.options"]["product/version"] = '"%s"' % VERSION
    export_config["preset.0.options"]["application/icon"] = '"res://icon.ico"'
    export_config["preset.0.options"]["application/product_version"] = '"%s"' % VERSION
    export_config["preset.0.options"]["application/company_name"] = '"Aleksandr Bazhin"'
    export_config["preset.0.options"]["application/product_name"] = '"TilePipe"'
    export_config["preset.0.options"]["application/file_description"] = '"Pipeline for tilesets"'
    # mac params
    export_config["preset.1.options"]["application/identifier"] = '"com.tilepipe.utility"'
    export_config["preset.1.options"]["application/icon"] = '"res://icon.icns"'
    export_config["preset.1.options"]["application/name"] = '"TilePipe"'
    export_config["preset.1.options"]["application/info"] = '"Pipeline for tilesets"'
    with open('export_presets.cfg', 'w') as configfile:
        export_config.write(configfile, space_around_delimiters=False)


def build():
    Path(EXPORT_PATH).mkdir(parents=True, exist_ok=True)
    shutil.rmtree("%(build_path)s" % WIN_PARAMS, ignore_errors=True)
    shutil.rmtree("%(build_path)s" % LINUX_PARAMS, ignore_errors=True)
    shutil.rmtree("%(build_path)s" % MAC_PARAMS, ignore_errors=True)
    Path(WIN_BUILD_PATH).mkdir(parents=True, exist_ok=True)
    Path(LINUX_BUILD_PATH).mkdir(parents=True, exist_ok=True)
    Path(MAC_BUILD_PATH).mkdir(parents=True, exist_ok=True)
   
    os.system('%(godot)s %(godot_params)s "Windows Desktop" %(build_path)s/%(binary)s' % WIN_PARAMS)
    os.system('%(godot)s %(godot_params)s "Linux/X11" %(build_path)s/%(binary)s' % LINUX_PARAMS)
    os.system('%(godot)s %(godot_params)s "Mac OSX" %(build_path)s/%(binary)s' % MAC_PARAMS)
    
def make_zip(target, source, is_mac: bool = False):
    if not is_mac:
        try:
            os.remove(target)
        except:
            pass
    os.system('7z a -r -tzip %s %s' % (target, source))


def prepare_uploads():
    shutil.rmtree("%s/examples" % EXPORT_PATH, ignore_errors=True)
    Path("%s/examples" % EXPORT_PATH).mkdir(parents=True, exist_ok=True)
    os.system("ROBOCOPY generation_data %s/examples *.png /xf *.png~" % EXPORT_PATH)
    make_zip('%s/examples.zip' % EXPORT_PATH, '%s/examples' % EXPORT_PATH)
    make_zip('%(path)s/%(app_name)s_win64.zip' % WIN_PARAMS,  '%(build_path)s/* %(path)s/examples' % WIN_PARAMS)
    make_zip('%(path)s/%(app_name)s_linux.zip' % LINUX_PARAMS,  '%(build_path)s/* %(path)s/examples' % LINUX_PARAMS)
    make_zip('%(build_path)s/%(binary)s' % MAC_PARAMS,  '%(path)s/examples' % MAC_PARAMS, is_mac=True)
    shutil.copyfile('%(build_path)s/%(binary)s' % MAC_PARAMS, '%(path)s/%(app_name)s_mac.zip' % MAC_PARAMS)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--build", action='store_true', default=False, help="Build binaries and prepare zip files for upload")
    parser.add_argument("-d", "--debug", action='store_true', default=False, help="Use debug flag for Godot and debug project when uploading")
    parser.add_argument("-u", "--upload", action='store_true', default=False, help="Upload to release or debug itch.io project")
    args = parser.parse_args()
    
    if args.debug:
        WIN_PARAMS["godot_params"] += "-debug"
        WIN_PARAMS["binary"] = WIN_PARAMS["binary"].replace(".exe", "_debug.exe")
        LINUX_PARAMS["godot_params"] += "-debug"
        LINUX_PARAMS["binary"] = LINUX_PARAMS["binary"].replace(".x86_64", "_debug.x86_64")
        MAC_PARAMS["godot_params"] += "-debug"
        MAC_PARAMS["binary"] = MAC_PARAMS["binary"].replace(".zip", "_debug.zip")

    if args.build:
        print("\n____________________TilePipe______________________\nBuilding with debug=%s\n" % str(args.debug))
        update_godot_export_templates()
        build()

    if args.upload:
        print("\n____________________TilePipe______________________\nPreparing upload with debug=%s\n" % str(args.debug))

        import os.path, sys
        if not os.path.isfile("%(build_path)s/%(binary)s" % WIN_PARAMS):
            sys.exit("ERROR: no Windows binary found, build project before uploading with the same debug flag (--debug is %s)" % str(args.debug))
        if not os.path.isfile("%(build_path)s/%(binary)s" % LINUX_PARAMS):
            sys.exit("ERROR: no Linux binary found, build project before uploading with the same debug flag (--debug is %s)" % str(args.debug))
        if not os.path.isfile("%(build_path)s/%(binary)s" % MAC_PARAMS):
            sys.exit("ERROR: no Mac binary found, build project before uploading with the same debug flag (--debug is %s)" % str(args.debug))
        
        prepare_uploads()

        print("\n____________________TilePipe______________________\nUploading build to itch.io")
        
        if args.debug:
            os.system('butler push %(path)s/%(app_name)s_win64.zip aleksandrbazhin/TilePipe-testing:windows-debug --userversion %(version)s' % WIN_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_linux.zip aleksandrbazhin/TilePipe-testing:linux-debug --userversion %(version)s' % LINUX_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_mac.zip  aleksandrbazhin/TilePipe-testing:mac-debug --userversion %(version)s' % MAC_PARAMS)
            
        else:
            # here upload to public TilePipe
            os.system('butler push %(path)s/%(app_name)s_win64.zip aleksandrbazhin/TilePipe:windows --userversion %(version)s' % WIN_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_linux.zip aleksandrbazhin/TilePipe:linux --userversion %(version)s' % LINUX_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_mac.zip  aleksandrbazhin/TilePipe:mac --userversion %(version)s' % MAC_PARAMS)
            os.system('butler push %(path)s/examples.zip  aleksandrbazhin/TilePipe:examples --userversion %(version)s' % {"path": EXPORT_PATH, "version": VERSION})
        

