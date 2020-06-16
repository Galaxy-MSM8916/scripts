#!/usr/bin/env python3

from . import config

def get_targets(distro):
    """
    Return targets for distro
    """

    targets = set()

    if distro in config.jobs:
        if "targets" in config.jobs[distro]:
            targets.update(set(config.jobs[distro]["targets"]))

    return targets

def get_build_types(distro):
    """
    Return build types for distro
    """

    types = set()

    if distro in config.jobs:
        if "types" in config.distros[distro]:
            types.update(set(config.jobs[distro]["types"]))

    return types
