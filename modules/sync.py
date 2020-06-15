#!/usr/bin/env python3

import os
import subprocess
import requests
from . import distros

manifest_repo_url = "https://raw.githubusercontent.com/Galaxy-MSM8916/local_manifests/master"

def get_manifest(distro, version):
    """
    Get manifest for distro
    """
    manifest_name = distro + "-" + version + ".xml"

    r = requests.get(manifest_repo_url + "/" + manifest_name)

    if (r.status_code != 200):
        return None

    return r.text

def get_dist_repo_dir(build_dir, distro, version):
    """
    Return repo source directory for distro
    """
    return build_dir + "/" + distro + "-" + version

def initialise_dist_repo(build_dir, distro, version):
    """
    Initialise repo source directory for distro with version
    """

    top_dir = os.environ['PWD']

    repo_path = top_dir + '/tools/repo'
    if not os.path.exists(repo_path):
        print("Error: could not find repo tool")
        os._exit(1)

    repo_url = distros.get_distro_repo_url(distro)
    if repo_url == None:
        print("Error: could not determine repo url")
        os._exit(1)

    repo_dir = get_dist_repo_dir(build_dir, distro, version)

    os.makedirs(repo_dir, exist_ok=True)
    os.chdir(repo_dir)

    if os.getcwd() == top_dir:
        print("Error: failed to change directory")
        os._exit(1)

    versions = []
    version_prefix = distros._get_distro_dict_value(distro, "init_prefix")
    if version_prefix == None or len(version_prefix) == 0:
        versions.append(version)
    else:
        versions = [ v + version for v in version_prefix]

    initialised = False
    for v in versions:

        args = [repo_path, "init", "-u", repo_url, "-b", v]

        try:
            result = subprocess.run(args, timeout=10, input="", text=True)

            if result.returncode == 0:
                initialised = True
                break
        except subprocess.TimeoutExpired:
            print("Timed out initialising repo")
            continue

    if not initialised:
        print("Error: could not initialise repo")
        os._exit(1)

    os.chdir(top_dir)
    