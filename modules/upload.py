#!/usr/bin/env python3

import os
import subprocess

def create_github_release(tag, description=None, repo = None, token = None, user = None):
    """
    Create a github release under tag in repo
    """
    top_dir = os.environ['PWD']
    release_tool_path = top_dir + '/tools/github-release'

    if not os.path.exists(release_tool_path):
        print("Error: could not find github release tool")
        os._exit(1)

    release_args = [release_tool_path, "info", "--tag", tag ]

    if repo:
        release_args.append("--repo")
        release_args.append(repo)

    if token:
        release_args.append("--security-token")
        release_args.append(token)

    if user:
        release_args.append("--user")
        release_args.append(user)

    # check if release exists
    res = subprocess.run(release_args)
    if res.returncode == 0:
        return

    release_args[1] = "release"

    if description:
        release_args.append("--description")
        release_args.append(description)

    # create release
    res = subprocess.run(release_args)
    if res.returncode == 0:
        print("Github release " + tag + " created")
        return
    else:
        print("Failed to create github release " + tag)
        os._exit(1)

def upload_github_artifact(tag, name, path, repo = None, token = None, user = None):
    """
    Upload an artifact at path under release tag in repo with name
    """
    top_dir = os.environ['PWD']
    release_tool_path = top_dir + '/tools/github-release'

    if not os.path.exists(release_tool_path):
        print("Error: could not find github release tool")
        os._exit(1)
    elif (not os.path.exists(path)) or os.path.isdir(path):
        print("Error: invalid release artifact specified")
        os._exit(1)

    release_args = [release_tool_path, "upload", "--tag", \
        tag, "--name", name, "--file", path, "--replace"]

    if repo:
        release_args.append("--repo")
        release_args.append(repo)

    if token:
        release_args.append("--security-token")
        release_args.append(token)

    if user:
        release_args.append("--user")
        release_args.append(user)

    print("Uploading release artifact " + name + " on tag " + tag)

    retries = 0
    retry_count = 3
    while retries < retry_count:
        res = subprocess.run(release_args)

        if res.returncode == 0:
            return
        else:
            print("Failed to upload release artifact at " \
                + path + ", retrying...")

            retries += 1

    print("Error: Failed to upload release artifact")
    os._exit(1)