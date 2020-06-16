#!/usr/bin/env python3

from . import config

def get_jobs_dict_value(distro, version, key):
    """
    Return value mapped to key in distro dictionary
    """
    if distro in config.jobs:
        if version in config.jobs[distro]:
            if key in config.jobs[distro][version]:
                return config.jobs[distro][version][key]

    return None

def get_targets(distro, version):
    """
    Return targets for distro
    """

    key = "targets"

    res = get_jobs_dict_value(distro, version, key)
    if res == None:
        return []

    return res

def get_build_variants(distro, version):
    """
    Return build variants for distro
    """

    key = "build_variants"

    res = get_jobs_dict_value(distro, version, key)
    if res == None:
        return []

    return res

def get_distro_versions(distro):
    """
    Return versions mapped to distro
    """

    if distro in config.jobs:
        return config.jobs[distro].keys()

    return set()

def get_devices(distro, version):
    """
    Return devices for distro
    """

    key = "devices"

    res = get_jobs_dict_value(distro, version, key)
    if res == None:
        return []

    return res

def get_repopicks(distro, version):
    """
    Return pair of repopick change ids and topics for distro
    """

    key = "picks"

    res = get_jobs_dict_value(distro, version, key)
    if res == None:
        return set(), set()

    picks = set()
    topics = set()

    for pick in res:
        try:
            picks.add(int(pick))
        except ValueError:
            topics.add(pick)

    return picks, topics

def get_lineage_repopicks(distro, version):
    """
    Return pair of lineage repopick change ids and topics for distro
    """

    key = "picks-lineage"

    res = get_jobs_dict_value(distro, version, key)
    if res == None:
        return set(), set()

    picks = set()
    topics = set()

    for pick in res:
        try:
            picks.add(int(pick))
        except ValueError:
            topics.add(pick)

    return picks, topics