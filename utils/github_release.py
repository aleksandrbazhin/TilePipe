import os
import shutil
import configparser
import requests
import json
from pathlib import Path


def create_git_tag(version):
    os.system(f"git tag {version}")


def push_git_tag():
    os.system(f"git push --tags")


def upload_github_release(user, version):
    print("Start github release process...")

    f = open(str(Path.home()) + '/.config/github/tilepipe_token')
    token = f.readline().rstrip()
    f.close()

    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json"
    }

    # create release
    data = {
        "tag_name": version,
        "target_commitish": "master",
        "name": f"TilePipe {version}",
        "body": f"TilePipe release {version}",
        "draft": False,
        "prerelease": False,
        "generate_release_notes": False
    }
    release_response = requests.post(f"https://api.github.com/repos/{user}/TilePipe/releases", 
        headers=headers, data=json.dumps(data))
    if release_response.ok:
        print(f"Release {version} created.")
    else:
        print(f"Error creating a release {version}")

    # check release and get its id
    release_id_response = requests.get(f"https://api.github.com/repos/{user}/TilePipe/releases/tags/{version}", 
            headers=headers, data=json.dumps({
            'owner': user,
            'repo': "TilePipe",
            'tag': version
    }))
    id = 0
    # upload_url = ""
    if release_id_response.ok:
        release_json = json.loads(release_id_response.content)
        id = release_json['id']
        # upload_url = release_json["upload_url"]
        print(f"Success finding the existing release {version}")
    else:
        print(f"Error finding the release {version}")
        return

    # upload release assets
    upload_headers = headers.copy()
    upload_headers["Content-Type"] = "application/binary"

    build_path = str(Path(f"../build/TilePipe2/"))

    for system in ('linux', 'win', 'mac'):
        print(f"Compressing: {system} release")
        output_filename = f"{build_path}/uploads/{system}_{version}"
        shutil.make_archive(output_filename, 'zip', f"{build_path}/{system}/")

        with open(f"{output_filename}.zip", 'rb') as file:
            print(f"Uploading: {system} release {version}")
            upload_response = requests.post(
                f"https://uploads.github.com/repos/{user}/TilePipe/releases/{id}/assets?name={system}_{version}.zip",
                headers=upload_headers, data = file.read())
            if(upload_response.ok):
                print(f"Upload success for {system} build")
            else:
                print(f"Error: upload failed for {system} build")
    print("Github export ended")


if __name__ == "__main__":    
    GITHUB_USER = 'aleksandrbazhin'
    override_config = configparser.ConfigParser()
    override_config.read("override.cfg")
    VERSION_FROM_CONFIG = override_config['application']['config/version'].replace('"', '')
    upload_github_release(GITHUB_USER, VERSION_FROM_CONFIG)

