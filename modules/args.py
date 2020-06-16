#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess

def parse_config_url():
    """
    Parse config url argument and fetch config
    """

    config_url_flag = "--config-url"
    config_url = None

    def print_help(error = None):
        print(sys.argv[0], "[" + config_url_flag + "url" + "]")
        print()

        if error == None:
            print("\t" + config_url_flag + " url  Config repo url.")
        else:
            print(error)

    for i in range(len(sys.argv)):
        if sys.argv[i] == config_url_flag:
            if i + 1 >= len(sys.argv):
                print_help("No url specified")
                os._exit(1)

            config_url = sys.argv[i + 1]
            break

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


def parse_args():
    """
    Parse program arguments
    """

    from . import distros

    parser = argparse.ArgumentParser(description='Build script.')

    parser.add_argument('-t', '--target', metavar='target', type=str, required=True, nargs=1, help='Build target.', choices=distros.get_targets())

    parser.add_argument('--config-url', metavar='git_url', type=str, nargs=1, help='Config url.')

    parser.add_argument('-d', '--device', metavar='device', type=str, nargs=1, help='Device codename.', choices=distros.get_devices())

    parser.add_argument('--build-dir', metavar='dir', type=str, nargs=1, help='Source/build directory', default='./build')

    parser.add_argument( '--distribution', '--distro', metavar='distribution', type=str, nargs=1, help='Distribution to build.', choices=distros.get_distros())

    parser.add_argument('--type', metavar='type', type=str, nargs=1, help='Type of build.', choices=distros.get_build_variants())

    parser.add_argument('--pick', metavar='number', type=int, nargs='+', help='Pick msm8916 gerrit changes.')
    parser.add_argument('--pick-lineage', metavar='number', type=int, nargs='+', help='Pick lineage gerrit changes.')

    parser.add_argument('--pick-topic', metavar='topic', type=str, nargs='+', help='Pick msm8916 gerrit topics.')
    parser.add_argument('--pick-lineage-topic', metavar='topic', type=str, nargs='+', help='Pick lineage gerrit topics.')

    parser.add_argument('-s', '--silent', action="store_true", help='Silence telegram notifications.')

    parser.add_argument('--clean', action="store_true", help="clean build top after completion.")

    parser.add_argument('--clean-device', action="store_true", help="clean build top after completion (only device subdir).")

    parser.add_argument('--days', metavar='num', type=int, nargs=1, help='Number of days of changelogs to generate.')

    return parser.parse_args().__dict__
