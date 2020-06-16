#!/usr/bin/env python3

import os
import subprocess
import requests
from . import distros

lineage_gerrit = 'https://review.lineageos.org'
msm8916_gerrit = 'https://review.msm8916.com'

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

    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

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

def write_manifest(distro, version, outpath):
    """
    Fetch and write manifest for distro to directory outpath
    """

    # get manifest
    manifest_xml = get_manifest(distro, version)
    if manifest_xml == None:
        print("Error: failed to fetch local manifest file")
        os._exit(1)

    os.makedirs(outpath, exist_ok=True)

    manifest_file = outpath + "/" + distro + "-" + version + ".xml"
    fhandle = open(manifest_file, "w")
    if fhandle == None:
        print("Error: failed to open local manifest file")
        os._exit(1)

    if fhandle.write(manifest_xml) != len(manifest_xml):
        print("Error: failed to write local manifest file")
        os._exit(1)

    fhandle.close()

def sync_dist_repo(build_dir, distro, version):
    """
    Sync source repo for distro
    """
    top_dir = os.environ['PWD']

    repo_tool_path = top_dir + '/tools/repo'
    if not os.path.exists(repo_tool_path):
        print("Error: could not find repo tool")
        os._exit(1)

    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    if not os.path.exists(repo_dir + "/.repo"):
        initialise_dist_repo(build_dir, distro, version)

    manifest_dir = repo_dir + "/.repo/local_manifests"

    if os.path.exists(manifest_dir):
        r = subprocess.run(["rm", "-rf", manifest_dir])

        if r.returncode != 0:
            print("Failed to remove old manifests")
            os._exit(1)

    os.makedirs(manifest_dir)

    write_manifest(distro, version, manifest_dir)

    os.chdir(repo_dir)
    if os.getcwd() == top_dir:
        print("Error: failed to change directory")
        os._exit(1)

    repo_args = [repo_tool_path, "sync", "--force-sync", \
        "--no-tags", "--no-clone-bundle", "--prune"]

    result = subprocess.run(repo_args, input="", text=True)
    if result.returncode != 0:
        print("Failed to sync repo")
        os._exit(1)

    os.chdir(top_dir)

def apply_repopicks(build_dir, distro, version, gerrit_url = lineage_gerrit, picks = [], topics = []):
    """
    Apply repopicks supplied in picks to distro
    """
    top_dir = os.environ['PWD']

    repopick_tool_path = top_dir + '/tools/repopick.py'
    if not os.path.exists(repopick_tool_path):
        print("Error: could not find repo tool")
        os._exit(1)

    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    os.chdir(repo_dir)
    if os.getcwd() == top_dir:
        print("Error: failed to change directory")
        os._exit(1)

    for pick in picks:
        repo_args = ["python3", repopick_tool_path, "-g", gerrit_url, \
            "-r", str(pick)]

        result = subprocess.run(repo_args, input="", text=True)
        if result.returncode != 0:
            print("Failed to pick change " + str(pick))
            os._exit(1)

    for topic in topics:
        repo_args = ["python3", repopick_tool_path, "-g", gerrit_url, \
            "-r", "-t", topic]

        result = subprocess.run(repo_args, input="", text=True)
        if result.returncode != 0:
            print("Failed to pick topic " + topic)
            os._exit(1)

    os.chdir(top_dir)