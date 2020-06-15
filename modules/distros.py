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

def get_variant_distro_parent(variant):
    """
    Return the name of variant distro's parent distro
    """
    search_key = "variants"
    for key in config.distros:
        if search_key in config.distros[key]:
            if variant in config.distros[key][search_key]:
                return key

    return None

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


def _get_distro_dict_value(distro, search_key):
    """
    Return value mapped to key in distro dictionary
    """
    for key in config.distros:
        if key == distro:
            if search_key in config.distros[key]:
                return config.distros[key][search_key]

        if "variants" not in config.distros[key]:
            continue

        for variant in config.distros[key]["variants"]:
            if variant == distro:
                if search_key in config.distros[key][variant]:
                    return config.distros[key][variant][search_key]
                elif search_key in config.distros[key]:
                    return config.distros[key][search_key]

    return None

def get_distro_versions(distro):
    """
    Return valid versions for distro
    """
    search_key = "versions"
    versions = []

    value = _get_distro_dict_value(distro, search_key)
    if (value != None):
        versions.extend(value)

    value = _get_distro_dict_value(distro, "variants")
    if (value != None):
        for variant in value:
            if distro != variant:
                continue
            elif search_key in value[variant]:
                versions.extend(value[variant][search_key])

    return versions

def get_distro_repo_url(distro):
    """
    Return sync url for distro
    """
    return _get_distro_dict_value(distro, "url")

