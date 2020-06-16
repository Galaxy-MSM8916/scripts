#!/usr/bin/env python3

import os
import subprocess
import requests

from . import distros

def get_cpu_count():
    """
    Returns the cpu count
    """
    try:
        import multiprocessing
        return multiprocessing.cpu_count()
    except (ImportError, NotImplementedError):
        return 2;

def build_target(build_dir, distro, version, device, target, build_variant):
    """
    Build target for device on distro
    """

    top_dir = os.environ['PWD']
    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    os.chdir(repo_dir)
    if os.getcwd() == top_dir:
        print("Error: failed to change directory")
        os._exit(1)

    dist_short = distros.get_variant_distro_parent(distro)
    if dist_short == None:
        dist_short = distro

    lunch_target = dist_short + "_" + device + "-" + build_variant
    job_count = str(get_cpu_count() - 1)

    build_args = [ "bash", "-c", "source build/envsetup.sh && " +\
         "lunch " + lunch_target + " && " +\
             "make -j" + job_count + " " + target ]

    res = subprocess.run(build_args, input = "", text = True)

    if res.returncode != 0:
        print("Build failed with return code " + str(res.returncode))
        os._exit(res.returncode)

    os.chdir(top_dir)

def get_bootimage_path(build_dir, distro, version, device):
    """
    Return path to boot image, or None if not found
    """
    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    bootimage_path = repo_dir + "/out/target/product/" \
         + device + "/boot.img"

    if os.path.exists(bootimage_path):
        return bootimage_path

    return None

def get_recoveryimage_path(build_dir, distro, version, device):
    """
    Return path to recovery image, or None if not found
    """
    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    recoveryimage_path = repo_dir + "/out/target/product/" \
         + device + "/recovery.img"

    if os.path.exists(recoveryimage_path):
        return recoveryimage_path

    return None

def get_otapackage_path(build_dir, distro, version, device):
    """
    Return path to ota package, or None if not found
    """
    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)
    out_path = repo_dir + "/out/target/product/" + device

    if not os.path.exists(out_path):
        return None

    dir_contents = os.listdir(out_path)

    for file in dir_contents:
        if file.endswith(".zip"):
            if device in file:
                return out_path + "/" + file

    return None