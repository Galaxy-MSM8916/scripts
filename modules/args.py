#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess

def parse_config_url():
    """
    Parse config url argument and fetch config
    and return command line args
    """

    args = []
    args.extend(sys.argv[1:])

    config_url_flag = "--config-url"
    config_url = None

    try:
        i = args.index(config_url_flag)

        if i + 1 >= len(sys.argv):
            args.append("-h")
            return args

        config_url = args[i + 1]

    except ValueError:
        return args

    conf_dir = os.getcwd() + "/conf"

    if os.path.exists(conf_dir):
        r = subprocess.run(["rm", "-rf", conf_dir])

        if r.returncode != 0:
            print("Failed to remove old repo")
            os._exit(1)

    if config_url != None:
        git_args = ["git", "clone", config_url, conf_dir]

        try:
            r = subprocess.run(git_args, timeout=20)

            if r.returncode != 0:
                print("Failed to fetch config repo")
                os._exit(1)
        except subprocess.TimeoutExpired:
                print("Failed to fetch config repo")
                os._exit(1)

    return args


def parse_args(args = None):
    """
    Parse program arguments
    """
    from . import devices
    from . import distros

    parser = argparse.ArgumentParser(description='Build script.')

    parser.add_argument('-t', '--target', metavar='target', type=str, nargs=1, help='Build target.', choices=distros.get_targets())

    parser.add_argument('--config-url', metavar='git_url', type=str, nargs=1, help='Config url.')

    parser.add_argument('-d', '--device', metavar='device', type=str, nargs=1, help='Device codename.', choices=devices.get_devices())

    parser.add_argument('--build-dir', metavar='dir', type=str, nargs=1, help='Source/build directory', default='./build')

    parser.add_argument( '--distribution', '--distro', metavar='distribution', type=str, nargs=1, help='Distribution to build.', choices=distros.get_distros())

    parser.add_argument( '--version', metavar='version', type=str, nargs=1, help='Distribution version to build.') #, choices=distros.get_distro_versions())

    parser.add_argument('--build-variant', metavar='build variant', type=str, nargs=1, help='Type of build.', choices=distros.get_build_variants())

    parser.add_argument('--pick', metavar='number', type=int, action="append", help='Pick msm8916 gerrit changes.')
    parser.add_argument('--pick-lineage', metavar='number', type=int, action="append", help='Pick lineage gerrit changes.')

    parser.add_argument('--pick-topic', metavar='topic', type=str, action="append", help='Pick msm8916 gerrit topics.')
    parser.add_argument('--pick-lineage-topic', metavar='topic', type=str, action="append", help='Pick lineage gerrit topics.')

    parser.add_argument('--force-pick', action="store_true", help='Force cherry pick even if change is closed.')

    parser.add_argument('--local-only', action="store_true", help="Don't fetch remote refs on sync.")

    parser.add_argument('--generate-pipelines', action="store_true", help="Generate build pipelines.")

    parser.add_argument('--clean', action="store_true", help="clean build top after completion.")

    parser.add_argument('--clean-device', action="store_true", help="clean build top after completion (only device subdir).")

    parsed = None

    if args == None:
        parsed = parser.parse_args()
    else:
        parsed = parser.parse_args(args)

    if not parsed.force_pick:
        parsed.force_pick = bool(int(os.environ.get("SCRIPT_FORCE_PICK") or 0)) # accepts 0 or 1

    if not parsed.clean_device:
        parsed.clean_device = bool(int(os.environ.get("SCRIPT_CLEAN_DEVICE") or 0)) # accepts 0 or 1

    if not parsed.local_only:
        parsed.local_only = bool(int(os.environ.get("SCRIPT_LOCAL_ONLY") or 0)) # accepts 0 or 1

    if not parsed.clean:
        parsed.clean = bool(int(os.environ.get("SCRIPT_CLEAN") or 0)) # accepts 0 or 1

    # Split env vars by commas, convert pick numbers to integers and put them in a list
    if os.environ.get("SCRIPT_PICKS"):
        repopicks = [int(x) for x in os.environ.get("SCRIPT_PICKS").split(',')]

        if parsed.pick:
            parsed.pick += repopicks
        else:
            parsed.pick = repopicks

    if os.environ.get("SCRIPT_PICKS_LINEAGE"):
        repopicks_lineage = [int(x) for x in os.environ.get("SCRIPT_PICKS_LINEAGE").split(',')]

        if parsed.pick_lineage:
            parsed.pick_lineage += repopicks_lineage
        else:
            parsed.pick_lineage = repopicks_lineage

    if os.environ.get("SCRIPT_PICK_TOPICS"):
        topics = os.environ.get("SCRIPT_PICK_TOPICS").split(',')

        if parsed.pick_topic:
            parsed.pick_topic += topics
        else:
            parsed.pick_topic = topics

    if os.environ.get("SCRIPT_PICK_LINEAGE_TOPICS"):
        topics_lineage = os.environ.get("SCRIPT_PICK_LINEAGE_TOPICS").split(',')

        if parsed.pick_lineage_topic:
            parsed.pick_lineage_topic += topics_lineage
        else:
            parsed.pick_lineage_topic = topics_lineage

    return parsed