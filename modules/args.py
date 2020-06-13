#!/usr/bin/env python3

import argparse

from . import distros

def parse_args():
    parser = argparse.ArgumentParser(description='Build script.')

    parser.add_argument('-t', '--target', metavar='target', type=str, required=True, nargs=1, help='Build target.', choices=distros.get_targets())

    parser.add_argument('-d', '--device', metavar='device', type=str, nargs=1, help='Device codename.', choices=distros.get_devices())

    parser.add_argument('--build-dir', metavar='dir', type=str, nargs=1, help='Source/build directory', default='./build')

    parser.add_argument( '--distribution', '--distro', metavar='distribution', type=str, nargs=1, help='Distribution to build.', choices=distros.get_distros())

    parser.add_argument('--type', metavar='type', type=str, nargs=1, help='Type of build.', choices=distros.get_build_types())

    parser.add_argument('--pick', metavar='number', type=int, nargs='+', help='Pick msm8916 gerrit changes.')
    parser.add_argument('--pick-lineage', metavar='number', type=int, nargs='+', help='Pick lineage gerrit changes.')

    parser.add_argument('--pick-topic', metavar='topic', type=str, nargs='+', help='Pick msm8916 gerrit topics.')
    parser.add_argument('--pick-lineage-topic', metavar='topic', type=str, nargs='+', help='Pick lineage gerrit topics.')

    parser.add_argument('-s', '--silent', action="store_true", help='Silence telegram notifications.')

    parser.add_argument('--clean', action="store_true", help="clean build top after completion.")

    parser.add_argument('--days', metavar='num', type=int, nargs=1, help='Number of days of changelogs to generate.')

    return parser.parse_args().__dict__
