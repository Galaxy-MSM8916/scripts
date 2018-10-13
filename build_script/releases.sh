#!/bin/bash

GITHUB_RELEASE=${script_dir}/tools/github-release

function create_release() {
    # first arg - tag;
    local tag=$1
    local release_desc="${JOB_DESCRIPTION}"

    if [ "x$release_desc" == "x" ]; then
        release_desc=$tag
     fi

    $GITHUB_RELEASE info -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $tag
    if [ "$?" != "0" ]; then
        $GITHUB_RELEASE release -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $tag --description "$release_desc"
	echoTextBlue "Release $tag created"
    else
	echoTextRed "Release $tag already exists"
    fi
    echo
}

function _upload_artifact() {
    # first arg tag; second arg - artifact
    local tag=$1
    local artifact_file=$2
    local artifact_name=`basename $artifact_file`
    local sync_count=1

    $GITHUB_RELEASE upload -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $tag --name $artifact_name --file $artifact_file
    sync_exit_error=$?

    while [ $sync_exit_error -ne 0 ] && [ $sync_count -le $UPLOAD_RETRY_COUNT ]; do
        echoTextRed "Failed to upload artifact ${artifact_name}. Retrying..."
        $GITHUB_RELEASE upload -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $tag --name $artifact_name --file $artifact_file --replace
        sync_exit_error=$?
        sync_count=$((sync_count+1))
    done

    exit_error $sync_exit_error
    echoTextBlue "Uploaded artifact ${artifact_name} to repo ${GITHUB_REPO} under release ${tag}."
    echo
}

function upload_artifacts() {
    # first arg tag; second arg - artifact
    local tag=$1
    local artifacts=$2
    if [ -d "$artifacts" ]; then
        for file in `find $artifacts -type f`; do
            _upload_artifact $tag $file
        done
    elif [ -f "$artifacts" ]; then
        _upload_artifact $tag $artifacts
    fi
}
