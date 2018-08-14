#!/bin/bash

# source 'script' functions
. $(dirname $0)/common/source.sh
# source common scripts
source_common

# update the repo
update_repo

NEWLINE="
"

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -i | --input Path to job description file or directory"
    echo "               containing decription files."

    echo "  -h | --help  Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -i | --input)           shift
                                JOB_FILE_INPUT=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

# find the job description files
if [ -f ${JOB_FILE_INPUT} ]; then
    JOB_DESC_FILES=${JOB_FILE_INPUT}
elif [ -d ${JOB_FILE_INPUT} ]; then
    JOB_DESC_FILES=$(find ${JOB_FILE_INPUT} -type f)
else
    echo "Invalid --input argument specified"
    exit 1
fi

function substitute_string {
# substitute_string $string
    new_string=`echo "$@" | sed s'/##/$/'g`
    eval "echo $new_string"
}

function split_variable {
# split_variable $variable
    echo $1 | sed s"/$SEPARATOR/ /"g
}

function extract_field {
# extract_field string $field_num $separator
    if [ "x$3" == "x" ]; then
        separator=':'
    else
        separator=$3
    fi
    echo $1 | cut -d "$separator" -f $2
}

function remove_underscores {
    result=$(echo $@ | sed s'/__/ /'g)
    result=$(echo $result | sed s'/_/ /'g)
    echo $result
}

for file in $JOB_DESC_FILES; do

    # clear some variables
    DEVICES=
    JOB_DESCRIPTION=
    JOB_DIR_PROPER=

    # source the job description files
    . $file

    # generate the job dirs
    while [ $(dirname $JOB_DIR) != "." ]; do
        JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"
        JOB_DIR=$(dirname $JOB_DIR)
    done
    JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"

    # save these variables for later use
    JOB_EXTENDED_DESCRIPTION_OLD=$JOB_EXTENDED_DESCRIPTION
    BUILD_DIR_OLD=$BUILD_DIR

    if [ "$BUILD_TARGET" == "otapackage" ] || [ "$BUILD_TARGET" == "bootimage" ] || [ "$BUILD_TARGET" == "recoveryimage" ]; then
        for DIST_VERSION in `split_variable $DIST_VERSION`; do
            for DEVICE_LINE in `split_variable $DEVICES`; do

                DEVICE_CODENAME=`extract_field $DEVICE_LINE 1`
                DEVICE_MODEL=`extract_field $DEVICE_LINE 2`
                DEVICE_EXTRA_DESC=`extract_field $DEVICE_LINE 3`
                DEVICE_EXTRA_DESC=`remove_underscores $DEVICE_EXTRA_DESC`

                JOB_EXTENDED_DESCRIPTION=`substitute_string $JOB_EXTENDED_DESCRIPTION_OLD`
                BUILD_DIR=`substitute_string $BUILD_DIR_OLD`

                JOB_BASE_NAME=${JOB_PREFIX}-${DIST_VERSION}-${DEVICE_CODENAME}
                JOB_DIR_PATH=${JENKINS_JOB_DIR}/${JOB_DIR_PROPER}/${JOB_BASE_NAME}/

                soc=`find_soc $DEVICE_CODENAME`
                HOST_NAME=jenkins.${soc}.com

                echo "https://${HOST_NAME}/job/$(echo ${JOB_DIR_PROPER}| sed s/jobs/job/g)${JOB_BASE_NAME}/badge/icon"

            done
            echo
        done
    fi
done
