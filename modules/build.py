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
