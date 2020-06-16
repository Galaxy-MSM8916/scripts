#!/usr/bin/env python3

import getopt
import os
import sys

def run_build(parse_args):
    """
    Run a source build
    """

    import modules.build as build
    import modules.config as config
    import modules.distros as distros
    import modules.sync as sync
    import modules.upload as upload

    # verify args
    if not parse_args.build_dir:
        print("No build dir specified")
        os._exit(1)
    elif not parse_args.target:
        print("No build target specified")
        os._exit(1)
    elif not parse_args.distribution:
        print("No distribution specified")
        os._exit(1)
    elif not parse_args.version:
        print("No distribution version specified")
        os._exit(1)
    elif not parse_args.device:
        print("No device specified")
        os._exit(1)
    elif not parse_args.build_variant:
        print("No build variant specified")
        os._exit(1)

    build_dir = os.path.realpath(parse_args.build_dir[0])
    target = parse_args.target[0]
    distribution = parse_args.distribution[0]
    version = parse_args.version[0]
    device = parse_args.device[0]
    build_variant = parse_args.build_variant[0]

    valid_versions = distros.get_distro_versions(distribution)
    if version not in valid_versions:
        print("Invalid version specified. Options are: " + valid_versions)
        os._exit(1)

    # set ccache stuff
    ccache_bin = "/usr/bin/ccache"

    if os.path.exists(ccache_bin):
        config.envvars["CCACHE_EXEC"] = ccache_bin
        config.envvars["CCACHE_DIR"] = build_dir + "/ccache"

    # update envvars
    os.environ.update(config.envvars)

    # sync repos
    sync.sync_dist_repo(build_dir, distribution, version, \
        local_only = parse_args.local_only)

    # apply repopicks
    repopicks = []
    topics = []
    repopicks_lineage = []
    topics_lineage = []

    if parse_args.pick:
        repopicks = parse_args.pick

    if parse_args.pick_lineage:
        repopicks_lineage = parse_args.pick_lineage

    if parse_args.pick_topic:
        topics = parse_args.pick_topic

    if parse_args.pick_lineage_topic:
        topics_lineage = parse_args.pick_lineage_topic

    sync.apply_repopicks(build_dir, distribution, version, \
        sync.lineage_gerrit, picks=repopicks_lineage, topics=topics_lineage)

    sync.apply_repopicks(build_dir, distribution, version, \
        sync.msm8916_gerrit, picks=repopicks, topics=topics)

    # build
    build.build_target(build_dir, distribution, version, device, target, build_variant)

    # get artifacts
    bootimage_path = build.get_bootimage_path(build_dir, distribution, version, device)
    recovery_path = build.get_recoveryimage_path(build_dir, distribution, version, device)
    otapackage_path = build.get_otapackage_path(build_dir, distribution, version, device)

    tag = build.get_build_release_tag(distribution, version, device, target)
    description = build.get_build_release_description(distribution, version, device)

    upload.create_github_release(tag, description)

    if bootimage_path:
        bootimage_name = build.get_bootimage_release_name(distribution, version, device)
        upload.upload_github_artifact(tag, bootimage_name, bootimage_path)

    if recovery_path:
        recovery_name = build.get_recoveryimage_release_name(distribution, version, device)
        upload.upload_github_artifact(tag, recovery_name, recovery_path)

    if otapackage_path:
        otapackage_name = build.get_otapackage_release_name(distribution, version, device)
        upload.upload_github_artifact(tag, otapackage_name, otapackage_path)

    # clean
    if parse_args.clean_device:
        print("Cleaning build directory...")
        build.clean_source_dir(build_dir, distribution, version, device)
    elif parse_args.clean:
        print("Cleaning build directory...")
        build.clean_source_dir(build_dir, distribution, version)

if __name__ == "__main__":

    import modules.args

    argv = modules.args.parse_config_url()
    parse_args = modules.args.parse_args(argv)

    run_build(parse_args)
