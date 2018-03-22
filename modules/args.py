#!/usr/bin/env python3

import argparse

from . import helpers

def parse_args():
    parser = argparse.ArgumentParser(description='Build script.')

    parser.add_argument('-t', '--target', metavar='target', type=str, required=True, nargs=1, help='Build target.', choices=helpers.get_targets())

    parser.add_argument('-d', '--device', metavar='device', type=str, nargs=1, help='Device codename.', choices=helpers.get_devices())

    parser.add_argument('--distro', '--distribution', metavar='distribution', type=str, nargs=1, help='Distribution to build.', choices=helpers.get_distros())

    parser.add_argument('--type', metavar='type', type=str, nargs=1, help='Type of build.', choices=helpers.get_build_types())

    parser.add_argument('--pick', metavar='pick', type=int, nargs='+', help='Pick msm8916 gerrit changes.')
    parser.add_argument('--pick-lineage', metavar='pick-lineage', type=int, nargs='+', help='Pick lineage gerrit changes.')

    parser.add_argument('--pick-topic', metavar='pick-topic', type=str, nargs='+', help='Pick msm8916 gerrit topics.')
    parser.add_argument('--pick-lineage-topic', metavar='pick-lineage-topic', type=str, nargs='+', help='Pick lineage gerrit topics.')

    parser.add_argument('-s', '--silent', metavar='silent', help='Silence telegram notifications.')

    parser.add_argument('--no-clean', metavar='no-clean', help="Don't clean build top after completion.")

    parser.add_argument('--days', metavar='days', type=int, nargs=1, help='Number of days of changelogs to generate.')

    args = parser.parse_args()
