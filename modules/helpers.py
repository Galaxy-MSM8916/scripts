#!/usr/bin/env python3
try:
    import conf
except ImportError:
    import conf_template as conf

def get_targets():
    """
    Return all valid targets
    """

    return conf.targets

def get_devices():
    """
    Return all valid devices
    """

    devices = set()

    for variant_map in conf.devices.values():
        devices.update(set(variant_map.keys()))

    return devices

def get_distros():
    """
    Return all valid distros
    """

    distros = set()

    for key in conf.distros:
        distros.add(key)

        if "variants" in conf.distros[key]:
            distros.update(set(conf.distros[key]["variants"]))

    return distros

def get_build_types():
    """
    Return all valid build types
    """

    types = set()

    for key in conf.distros:
        if "types" in conf.distros[key]:
            types.update(set(conf.distros[key]["types"]))

def get_distro_versions(distro):
    """
    Return valid versions for distro
    """
    versions = []

    for key in conf.distros:
        if key == distro:
            if "versions" in conf.distros[key]:
                versions.extend(conf.distros[key]["versions"])

            break

        if "variants" not in conf.distros[key]:
            continue

        for variant in conf.distros[key]["variants"]:
            if variant == distro:
                if "versions" in conf.distros[key]:
                    versions.extend(conf.distros[key]["versions"])

                if "versions" in conf.distros[key][variant]:
                    versions.extend(conf.distros[key][variant]["versions"])

                break

    return versions

def get_job_targets(job):
    """
    Return targets for job
    """

    targets = set()

    if job in conf.jobs:
        if "targets" in conf.jobs[job]:
            targets.update(set(conf.jobs[job]["targets"]))

    return targets

def get_job_build_types(job):
    """
    Return build types for job
    """

    types = set()

    if job in conf.jobs:
        if "types" in conf.distros[job]:
            types.update(set(conf.jobs[job]["types"]))

    return types
