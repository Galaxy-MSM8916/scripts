#!/bin/bash

# source common functions
for file in `find common -name '*sh'`; do
    . $file
done

if [ "x$GO" == "x" ];then
    GO=0
fi

SUCCESS=0

TRANSMISSION_ROOT=/var/lib/transmission-daemon/downloads/

function get_ota_root() {
# first arg - device name
   arch=`find_arch $1`

    if [ $GO -eq 0 ]; then
        local ota_root=/var/www/ota${VERSION}.${arch}.com/public_html/
    else
        local ota_root=/var/www/ota${VERSION}-go.${arch}.com/public_html/
    fi

    echo $ota_root
}

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -t | --target One of promote/demote"
    echo "  -d | --device device codename"
    echo "  -g | --go Promote go edition"
    echo "  -j | --job # to promote."
    echo "  -v | --version Lineage version (one of 14,15)"
    echo "  -h | --help  Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -d | --device)          shift
                                DEVICE=$1
                                ;;
        -g | --go)              shift
                                GO=1
                                ;;
        -j | --job)             shift
                                JOB_NUM=$1
                                ;;
        -t | --target)          shift
                                TARGET=$1
                                ;;
        -v | --version)         shift
                                VERSION=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

if [ "x$JOB_NUM" == "x" ] && [ "x$TARGET" != "xdemote" ]; then
    echo "No job number specified for promotion"
    print_help
fi

if [ "x$VERSION" != "x14" ] && [ "x$VERSION" != "x15" ]; then
    if [ -z "$VERSION" ]; then
        echo "No version specified"
    else
        echo "Invalid version $VERSION specified"
    fi
    print_help
fi

if [ "x$TARGET" != "xpromote" ] && [ "x$TARGET" != "xdemote" ]; then
    if [ -z "$TARGET" ]; then
        echo "No target specified"
    else
        echo "Invalid target $TARGET specified"
    fi
    print_help
fi

if [ -z "$JENKINS_HOME" ]; then
    JENKINS_HOME=/var/lib/jenkins
fi

update_job_repo
generate_device_list

if [ "x$TARGET" == "xpromote" ]; then
    if [ $GO -eq 0 ]; then
        JENKINS_JOB_DIR="${JENKINS_HOME}/jobs/LineageOS_Builds"
        JOB_REGEXP="lineage-${VERSION}"'*'"_j${JOB_NUM}_"'*'"${DEVICE}"'*'
    else
        JENKINS_JOB_DIR="${JENKINS_HOME}/jobs/LineageOS_GO_Builds"
        JOB_REGEXP="lineage-go-${VERSION}"'*'"_j${JOB_NUM}_"'*'"${DEVICE}"'*'
    fi

    SEARCH_PATH="
    "`find ${JENKINS_JOB_DIR} -type d -name 'los-*'"${VERSION}"'*'"-${DEVICE}" 2>/dev/null || true`/builds/${JOB_NUM}/archive/builds/"
    `find ${TRANSMISSION_ROOT} -type d -name $JOB_REGEXP 2>/dev/null || true`
    "

    OTA_ROOT=`get_ota_root $DEVICE`

    for path in $SEARCH_PATH; do
        [ -d ${path} ] || continue;
        rm -f ${OTA_ROOT}/builds/full/*${VERSION}*${DEVICE}.*
        find ${path} -name ${JOB_REGEXP}'*zip.prop' -type f -execdir ln '{}' ${OTA_ROOT}/builds/full/ \; || continue
        find ${path} -name ${JOB_REGEXP}'*zip' -type f -execdir ln '{}' ${OTA_ROOT}/builds/full/ \; || continue
        find ${path} -name 'changelog-'${JOB_REGEXP}'*txt' -type f -execdir ln '{}' ${OTA_ROOT}/builds/full/ \; || continue
        find ${path} -name ${JOB_REGEXP}'*md5' -type f -execdir cp '{}' ${OTA_ROOT}/builds/full/ \; || continue
        rename s'/-go//'g ${OTA_ROOT}/builds/full/*
        rename s'/_j[0-9]*_/-/'g ${OTA_ROOT}/builds/full/*
        find ${OTA_ROOT}/builds/full/ -type f -execdir rename s'/_/-/'g '{}' \; || true
        rename s'/changelog-//'g ${OTA_ROOT}/builds/full/*
        rename s'/zip\.md5/md5sum/'g  ${OTA_ROOT}/builds/full/*
        sed -i s'/_j[0-9]*_/-/'g ${OTA_ROOT}/builds/full/*md5sum
        sed -i s'/_/-/'g ${OTA_ROOT}/builds/full/*md5sum
        SUCCESS=1
    done
else
    rm -f ${OTA_ROOT}/builds/full/*${VERSION}*${DEVICE}.*
    SUCCESS=1
fi

if [ $SUCCESS -eq 0 ]; then
    [ "x$TARGET" == "xpromote" ] && echo "Failed to promote LineageOS-${VERSION} image #${JOB_NUM} for ${DEVICE}."
    [ "x$TARGET" == "xdemote" ] && echo "Failed to demote LineageOS-${VERSION} image for ${DEVICE}."
    exit 1
else
    [ "x$TARGET" == "xpromote" ] && echo "Promoted LineageOS-${VERSION} image #${JOB_NUM} for ${DEVICE}."
    [ "x$TARGET" == "xdemote" ] && echo "Demoted LineageOS-${VERSION} image for ${DEVICE}."
    exit 0
fi
