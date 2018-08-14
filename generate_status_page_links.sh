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

for file in $JOB_DESC_FILES; do

    # clear some variables
    DEVICES=
    JOB_DIR_PROPER=

    # source the job description files
    . $file

    # generate the job dirs
    while [ $(dirname $JOB_DIR) != "." ]; do
        JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"
        JOB_DIR=$(dirname $JOB_DIR)
    done
    JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"

    if [ "$BUILD_TARGET" == "otapackage" ] || [ "$BUILD_TARGET" == "bootimage" ] || [ "$BUILD_TARGET" == "recoveryimage" ]; then
        for DIST_VERSION in `split_variable $DIST_VERSION`; do
            for DEVICE_LINE in `split_variable $DEVICES`; do

                DEVICE_CODENAME=`extract_field $DEVICE_LINE 1`

                JOB_BASE_NAME=${JOB_PREFIX}-${DIST_VERSION}-${DEVICE_CODENAME}

                soc=`find_soc $DEVICE_CODENAME`
                HOST_NAME=jenkins.${soc}.com

                echo "https://${HOST_NAME}/job/$(echo ${JOB_DIR_PROPER}| sed s/jobs/job/g)${JOB_BASE_NAME}/badge/icon"

            done
            echo
        done
    fi
done
