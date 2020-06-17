#!/usr/bin/env python3

import os
import time
import subprocess
import requests

from . import config
from . import devices
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

    res = subprocess.run(build_args, input = "", encoding="utf-8")

    if res.returncode != 0:
        print("Build failed with return code " + str(res.returncode))
        os._exit(res.returncode)

    os.chdir(top_dir)

def clean_source_dir(build_dir, distro, version, device = None):
    """
    Clean source dir of build intermediates.

    If device is specified, remove only device artifacts/intermediates
    """
    repo_dir = distros.get_distro_repo_dir(build_dir, distro, version)

    out_path = repo_dir + "/out"

    if device != None:
        out_path += "/target/product/" + device

    res = subprocess.run(["rm", "-rf", out_path])

    if res.returncode != 0:
        print("Failed to remove directory " + out_path)
        os._exit(res.returncode)

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

    ota_path = None
    newest_mtime = -1

    for file in dir_contents:
        if file.endswith(".zip"):
            if device in file:
                fpath = out_path + "/" + file
                mtime = os.path.getmtime(fpath)

                if mtime > newest_mtime:
                    newest_mtime = mtime
                    ota_path = fpath

    return ota_path

def get_short_date():
    """
    Return date in yyyymmdd format
    """
    st = time.localtime()
    date = str(st.tm_year)

    if st.tm_mon < 10:
        date += "0"

    date += str(st.tm_mon)

    if st.tm_mday < 10:
        date += "0"

    date += str(st.tm_mday)

    return date

def get_buildtype():
    """
    Return build type
    """
    buildtype = "UNOFFICIAL"

    if "LINEAGE_BUILDTYPE" in config.envvars:
        buildtype = config.envvars["LINEAGE_BUILDTYPE"]

    return buildtype

def get_build_release_description(distro, version, device):
    """
    Return descriptive build description
    """
    distro_name = distros.get_long_distro_name(distro)
    device_long = devices.get_long_device_name(device)
    device_model = devices.get_device_model(device)

    return distro_name + " " + version + " for the " \
        + device_long + " (" + device_model + ")"

def get_bootimage_release_name(distribution, version, device):
    """
    Return name of boot image for use in release upload
    """
    return "boot-" + distribution + "-" + version \
        + "-" + get_short_date() + "-" + device + ".img"

def get_recoveryimage_release_name(distribution, version, device):
    """
    Return name of recovery image for use in release upload
    """
    return "recovery-" + distribution + "-" + version \
        + "-" + get_short_date() + "-" + device + ".img"

def get_otapackage_release_name(distribution, version, device):
    """
    Return name of ota image for use in release upload
    """
    return distribution + "-" + version + "-" + get_short_date() \
        + "-" + get_buildtype() + "-" + device + ".zip"

def get_build_release_tag(distribution, version, device, target):
    """
    Return tag name for use in release upload
    """
    delim = "."
    tag = None
    if target == "recoveryimage":
        tag = get_recoveryimage_release_name(distribution, version, device)
    elif target == "bootimage":
        tag = get_bootimage_release_name(distribution, version, device)
    else:
        tag = get_otapackage_release_name(distribution, version, device)

    split = tag.split(delim)
    split.pop()

    tag = ""
    for i in range(len(split)):
        tag += split[i]
        tag += delim

    return tag.strip(delim)
