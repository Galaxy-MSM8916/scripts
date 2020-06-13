#!/usr/bin/env python3

from . import config

def get_targets(job):
    """
    Return targets for job
    """

    targets = set()

    if job in config.jobs:
        if "targets" in config.jobs[job]:
            targets.update(set(config.jobs[job]["targets"]))

    return targets

def get_build_types(job):
    """
    Return build types for job
    """

    types = set()

    if job in config.jobs:
        if "types" in config.distros[job]:
            types.update(set(config.jobs[job]["types"]))

    return types
