#!/usr/bin/env python3
from . import config

def get_targets():
    """
    Return all valid targets
    """

    return config.targets

def get_devices():
    """
    Return all valid devices
    """

    devices = set()

    for variant_map in config.devices.values():
        devices.update(set(variant_map.keys()))

    return devices

def get_build_types():
    """
    Return all valid build types
    """

    types = set()

    for key in config.distros:
        if "types" in config.distros[key]:
            types.update(set(config.distros[key]["types"]))



def get_distros():
    """
    Return all valid distros
    """

    distros = set()

    for key in config.distros:
        distros.add(key)

        if "variants" in config.distros[key]:
            distros.update(set(config.distros[key]["variants"]))

    return distros

def get_distro_versions(distro):
    """
    Return valid versions for distro
    """
    versions = []

    for key in config.distros:
        if key == distro:
            if "versions" in config.distros[key]:
                versions.extend(config.distros[key]["versions"])

            break

        if "variants" not in config.distros[key]:
            continue

        for variant in config.distros[key]["variants"]:
            if variant == distro:
                if "versions" in config.distros[key]:
                    versions.extend(config.distros[key]["versions"])

                if "versions" in config.distros[key][variant]:
                    versions.extend(config.distros[key][variant]["versions"])

                break

    return versions


