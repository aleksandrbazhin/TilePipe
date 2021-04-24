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

WIN_PARAMS = {"godot": GODOT33, "godot_params": "--no-window --export",  "path": EXPORT_PATH, "build_path": WIN_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.exe" % APP_NAME}
LINUX_PARAMS = {"godot": GODOT33, "godot_params": "--no-window --export", "path": EXPORT_PATH, "build_path": LINUX_BUILD_PATH, "app_name": APP_NAME, "binary": "%s.x86_64" % APP_NAME}
MAC_PARAMS = {"godot": GODOT323, "godot_params": "--no-window --export", "path": EXPORT_PATH, "build_path": MAC_BUILD_PATH, "app_name": APP_NAME, "binary": "%s_mac.zip" % APP_NAME}


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
    
def prepare_uploads():
    shutil.rmtree("%s/examples" % EXPORT_PATH, ignore_errors=True)
    Path("%s/examples" % EXPORT_PATH).mkdir(parents=True, exist_ok=True)
    os.system("ROBOCOPY  generation_data %s/examples *.png" % EXPORT_PATH)
    
    os.remove('%(path)s/%(app_name)s_win64.zip' % WIN_PARAMS)
    os.system('7z a -r -tzip %(path)s/%(app_name)s_win64.zip %(build_path)s/* %(path)s/examples' % WIN_PARAMS)
    
    os.remove('%(path)s/%(app_name)s_linux.zip' % LINUX_PARAMS)
    os.system('7z a -r -tzip %(path)s/%(app_name)s_linux.zip %(build_path)s/* %(path)s/examples' % LINUX_PARAMS)
    
    os.system('7z a -r -tzip %(build_path)s/%(binary)s %(path)s/examples' % MAC_PARAMS)
    shutil.copyfile('%(build_path)s/%(binary)s' % MAC_PARAMS, '%(path)s/%(app_name)s_mac.zip' % MAC_PARAMS)
    # os.system('ROBOCOPY )

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
        print("\n____________________TilePipe______________________\nPreparing uppload with debug=%s\n" % str(args.debug))

        import os.path, sys
        if not os.path.isfile("%(build_path)s/%(binary)s" % WIN_PARAMS):
            sys.exit("ERROR: no Windows binary found, build project before upploading with the same debug flag (--debug is %s)" % str(args.debug))
        if not os.path.isfile("%(build_path)s/%(binary)s" % LINUX_PARAMS):
            sys.exit("ERROR: no Linux binary found, build project before upploading with the same debug flag (--debug is %s)" % str(args.debug))
        if not os.path.isfile("%(build_path)s/%(binary)s" % MAC_PARAMS):
            sys.exit("ERROR: no Mac binary found, build project before upploading with the same debug flag (--debug is %s)" % str(args.debug))
        
        prepare_uploads()

        print("\n____________________TilePipe______________________\nUploading build to itch.io")
        
        if args.debug:
            os.system('butler push %(path)s/%(app_name)s_win64.zip aleksandrbazhin/TilePipe-testing:windows-debug' % WIN_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_linux.zip aleksandrbazhin/TilePipe-testing:linux-debug' % LINUX_PARAMS)
            os.system('butler push %(path)s/%(app_name)s_mac.zip  aleksandrbazhin/TilePipe-testing:mac-debug' % MAC_PARAMS)
            
        else:
            # here upload to public TilePipe
            pass 
            # os.system('butler push %(path)s/%(app_name)s_win64.zip aleksandrbazhin/TilePipe-testing:windows' % WIN_PARAMS)
            # os.system('butler push %(path)s/%(app_name)s_linux.zip aleksandrbazhin/TilePipe-testing:linux' % LINUX_PARAMS)
            # os.system('butler push %(path)s/%(app_name)s_mac.zip  aleksandrbazhin/TilePipe-testing:mac' % MAC_PARAMS)
        

