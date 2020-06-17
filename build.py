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

def generate_pipelines(parse_args):
    """
    Generate build pipelines
    """
    import modules.build
    import modules.jobs

    import subprocess

    buildkite_yaml = "steps:\n"

    base_args = []

    base_args.append(sys.argv[0])

    if parse_args.build_dir:
        base_args.append("--build-dir")

        if type(parse_args.build_dir) == str:
            base_args.append(parse_args.build_dir)
        else:
            base_args.append(parse_args.build_dir[0])

    if parse_args.config_url:
        base_args.append("--config-url")
        base_args.append(parse_args.config_url[0])

    if parse_args.local_only:
        base_args.append("--local-only")

    if parse_args.clean:
        base_args.append("--clean")

    if parse_args.clean_device:
        base_args.append("--clean-device")

    distributions = []

    if parse_args.distribution:
        distributions.extend(parse_args.distribution)
    else:
        distributions.extend(modules.jobs.get_distros())

    for distribution in distributions:

        versions = []

        if parse_args.version:
            versions.extend(parse_args.version)
        else:
            versions.extend(modules.jobs.get_distro_versions(distribution))

        for version in versions:

            build_variants = []
            devices = []
            repopicks = []
            topics = []
            repopicks_lineage = []
            topics_lineage = []

            targets = []

            if parse_args.build_variant:
                build_variants.extend(parse_args.build_variant)
            else:
                build_variants.extend(modules.jobs.get_build_variants(distribution, version))

            if parse_args.device:
                devices.extend(parse_args.device)
            else:
                devices.extend(modules.jobs.get_devices(distribution, version))

            if parse_args.target:
                targets.extend(parse_args.target)
            else:
                targets.extend(modules.jobs.get_targets(distribution, version))

            if parse_args.pick:
                repopicks = parse_args.pick
            else:
                repopicks = modules.jobs.get_repopicks(distribution, version)[0]

            if parse_args.pick_lineage:
                repopicks_lineage = parse_args.pick_lineage
            else:
                repopicks_lineage = modules.jobs.get_lineage_repopicks(\
                    distribution, version)[0]

            if parse_args.pick_topic:
                topics = parse_args.pick_topic
            else:
                topics = modules.jobs.get_repopicks(distribution, version)[1]

            if parse_args.pick_lineage_topic:
                topics_lineage = parse_args.pick_lineage_topic
            else:
                topics_lineage = modules.jobs.get_lineage_repopicks(\
                    distribution, version)[1]

            for device in devices:
                for build_variant in build_variants:
                    for target in targets:

                        script_args = []

                        script_args.append("--distribution")
                        script_args.append(distribution)

                        script_args.append("--version")
                        script_args.append(version)

                        script_args.append("--device")
                        script_args.append(device)

                        script_args.append("--build-variant")
                        script_args.append(build_variant)

                        script_args.append("--target")
                        script_args.append(target)

                        for repopick in repopicks:
                            script_args.append("--pick")
                            script_args.append(str(repopick))

                        for repopick in repopicks_lineage:
                            script_args.append("--pick-lineage")
                            script_args.append(str(repopick))

                        for topic in topics:
                            script_args.append("--pick-topic")
                            script_args.append(str(topic))

                        for topic in topics_lineage:
                            script_args.append("--pick-lineage-topic")
                            script_args.append(str(topic))

                        desc = modules.build.get_build_release_description(\
                            distribution, version, device)

                        buildkite_yaml += "    - label: " + desc + "\n"
                        buildkite_yaml += "      command: "

                        for arg in base_args:
                            buildkite_yaml += arg
                            buildkite_yaml += " "

                        for arg in script_args:
                            buildkite_yaml += arg
                            buildkite_yaml += " "

                        buildkite_yaml += "\n"
                        buildkite_yaml += "      retry:\n"
                        buildkite_yaml += "         automatic: false\n"
                        buildkite_yaml += "\n"

    buildkite_args =["buildkite-agent", "pipeline", "upload"]

    res = subprocess.run(buildkite_args, input=buildkite_yaml, encoding="utf-8")
    if res.returncode != 0:
        print("Failed to upload pipeline")
        os._exit(res.returncode)

if __name__ == "__main__":

    import modules.args

    argv = modules.args.parse_config_url()
    parse_args = modules.args.parse_args(argv)

    if parse_args.generate_pipelines:
        generate_pipelines(parse_args)
    else:
        run_build(parse_args)
