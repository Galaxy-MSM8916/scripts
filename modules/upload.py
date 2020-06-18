#!/usr/bin/env python3

import os
import subprocess
import tempfile

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

def upload_sourceforge(tag, name, path, user = None, \
    host = None, project = None, identity_file = None):
    """
    Upload an artifact to sourceforge
    """
    if (not os.path.exists(path)) or os.path.isdir(path):
        print("Error: invalid release artifact specified")
        os._exit(1)

    if not user:
        key = "SF_USER"
        if key not in os.environ:
            print("Error: No ssh user specified")
            os._exit(1)

        user = os.environ[key]

    if not host:
        key = "SF_HOST"
        if key not in os.environ:
            print("Error: No ssh host specified")
            os._exit(1)

        host = os.environ[key]

    if not project:
        key = "SF_PROJECT"
        if key not in os.environ:
            print("Error: No sourceforge project specified")
            os._exit(1)

        project = os.environ[key]

    using_tempfile_id = False

    if not (identity_file and os.path.exists(identity_file)):
        key = "SF_IDENTITY_KEY"
        if key not in os.environ:
            print("Error: No identity file specified")
            os._exit(1)

        temp = tempfile.NamedTemporaryFile("w", delete=False)
        temp.write(bytes(os.environ[key], encoding="utf-8"))
        temp.close()

        identity_file = temp.name
        using_tempfile_id = True

    ssh_command = "ssh -o StrictHostKeyChecking=no -i " + identity_file

    output_dir = "/home/frs/project/" + project + \
        "/" + tag

    # create output directory
    with tempfile.TemporaryDirectory() as tmpdir:
        rsync_args = ["rsync", "-e", ssh_command, "-r", \
            tmpdir, user + "@" + host + ":" + output_dir]

        res = subprocess.run(rsync_args, input="", encoding="utf-8")
        if (res.returncode != 0):
            print("Error: Failed to create output directory on sourceforge")
            os._exit(1)

    # copy artifact
    rsync_args = ["rsync", "-e", ssh_command, "--progress", \
        path, user + "@" + host + ":" + output_dir + "/" + name]

    retries = 0
    retry_count = 3
    while retries < retry_count:
        res = subprocess.run(rsync_args, input="", encoding="utf-8")

        if res.returncode == 0:
            if using_tempfile_id:
                os.remove(identity_file)

            return
        else:
            print("Failed to upload release artifact at " \
                + path + ", retrying...")

            retries += 1

    if using_tempfile_id:
        os.remove(identity_file)

    print("Error: Failed to upload release artifact")
    os._exit(1)