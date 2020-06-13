#!/usr/bin/env python3
try:
    import conf
except ImportError:
    import conf_template as conf

def get_targets(job):
    """
    Return targets for job
    """

    targets = set()

    if job in conf.jobs:
        if "targets" in conf.jobs[job]:
            targets.update(set(conf.jobs[job]["targets"]))

    return targets

def get_build_types(job):
    """
    Return build types for job
    """

    types = set()

    if job in conf.jobs:
        if "types" in conf.distros[job]:
            types.update(set(conf.jobs[job]["types"]))

    return types
