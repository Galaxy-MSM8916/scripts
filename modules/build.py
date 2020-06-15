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

def build_target(build_dir, distro, version, device, target, buildtype):
    """
    Build target for device on distro
    """
    top_dir = os.environ['PWD']

    repo_dir = distros.get_dist_repo_dir(build_dir, distro, version)

    os.chdir(repo_dir)
    if os.getcwd() == top_dir:
        print("Error: failed to change directory")
        os._exit(1)

    dist_short = distros.get_variant_distro_parent(distro)
    if dist_short == None:
        dist_short = distro

    build_args = ["bash", "-c", "\"", "source" "build/envsetup.sh", "&&", \
         "lunch", dist_short + "_" + device + "-" + buildtype, "&&", \
             "make", "-j" + str(get_cpu_count() - 1), target, "\""]

    res = subprocess.run(build_args, input = "", text = True)

    if res.returncode != 0:
        print("Build failed with return code " + str(res.returncode))
        os.exit(res.returncode)
    
    os.chdir(top_dir)

