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

def get_build_variants(distro):
    """
    Return build variants for distro
    """

    build_variants = set()

    if distro in config.jobs:
        if "build_variants" in config.distros[distro]:
            build_variants.update(set(config.jobs[distro]["build_variants"]))

    return build_variants
