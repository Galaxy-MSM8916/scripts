#!/bin/bash

GITHUB_USER=Galaxy-MSM8916
GITHUB_TOKEN=
GITHUB_REPO=releases

GITHUB_RELEASE=$(realpath `dirname $0`)/tools/github-release

function create_release() {
    $GITHUB_RELEASE info -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $TAG
    if [ "$?" != "0" ]; then
        $GITHUB_RELEASE release -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $TAG --name $RELEASE_NAME
        echo "Release $RELEASE_NAME created"
    else
        echo "Release $RELEASE_NAME already exists"
    fi
}

function upload_artifact() {
# first arg - artifact
    local artifact_file=$1
    local artifact_name=`basename $artifact_file`
    local sync_count=1

    $GITHUB_RELEASE upload -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $TAG --name $artifact_name --file $artifact_file
    sync_exit_error=$?

    while [ $sync_exit_error -ne 0 ] && [ $sync_count -le 3 ]; do
        echo "Failed to upload artifact ${artifact_name}. Retrying..."
        $GITHUB_RELEASE upload -s $GITHUB_TOKEN --user $GITHUB_USER --repo $GITHUB_REPO --tag $TAG --name $artifact_name --file $artifact_file --replace
        sync_exit_error=$?
        sync_count=$((sync_count+1))
    done
    echo "Uploaded artifact ${artifact_name} to repo ${GITHUB_REPO} under release ${RELEASE_NAME}."
}

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -a | --artifact File/directory to upload"
    echo "  -t | --tag Git tag name"
    echo "  -n | --name Release name"
    echo "  -h | --help  Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -a | --artifact)     shift
                                ARTIFACT=$1
                                ;;
        -n | --name)         shift
                                RELEASE_NAME=$1
                                ;;
        -t | --tag)          shift
                                TAG=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

if [ "x$TAG" == "x" ]; then
    echo "No tag specified."
    print_help
fi

if [ "x$RELEASE_NAME" == "x" ]; then
    RELEASE_NAME=$TAG
fi

if [ "x$ARTIFACT" == "x" ]; then
    echo "No artifact(s) specified"
    print_help
fi

create_release

if [ -d "$ARTIFACT" ]; then
    for file in `find $ARTIFACT -type f`; do
        upload_artifact $file
    done
elif [ -f "$ARTIFACT" ]; then
    upload_artifact $ARTIFACT
fi
