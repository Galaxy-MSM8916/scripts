#!/bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function make_targets {
    #start building
    if [ "x$ver" == "x13.0" ]; then
        MAKE_ARGS+="CM_UPDATER_OTA_URI=cm.updater.uri=https://ota13.${arch}.com/api CM_BUILDTYPE=NIGHTLY"
    elif [ "x$ver" == "x14.1" ]; then
        MAKE_ARGS+="CM_UPDATER_OTA_URI=cm.updater.uri=https://ota14.${arch}.com/api CM_BUILDTYPE=NIGHTLY"
    elif [ "x$ver" == "x15.0" ]; then
        MAKE_ARGS+="CM_UPDATER_OTA_URI=lineage.updater.uri=https://ota15.${arch}.com/api LINEAGE_BUILDTYPE=NIGHTLY"
    elif [ "x$ver" == "x15.1" ]; then
        MAKE_ARGS+="LINEAGE_BUILDTYPE=NIGHTLY"
    fi
    exit_on_failure make -j${JOB_NUMBER} $BUILD_TARGET $MAKE_ARGS
}

function generate_log {
    # generate_log /path/to/git/tree

    # try to use a preset time (7 days ago)
    dates=$(date -d "`date` - $CHANGELOG_DAYS days" +%Y%m%d)
    GIT_PATH=$1
    LOG=`git -C $GIT_PATH log --decorate=full --since=$(date -d ${dates[0]} +%m-%d-%Y)`

    if [ "x$LOG" == "x" ]; then
        # output the last 6 commits
        git -C $GIT_PATH log --decorate=full -n 6
    else
        git -C $GIT_PATH log --decorate=full --since=$(date -d ${dates[0]} +%m-%d-%Y)
    fi
}

function generate_changes {
    logb "Generating changes..."

    changelog_name=changelog-${arc_name}.txt

    echo -e "\n${arch^^}-COMMON\n---------\n" > ${ARTIFACT_OUT_DIR}/${changelog_name}
    generate_log ${platform_common_dir} >> ${ARTIFACT_OUT_DIR}/${changelog_name}

    echo -e "\nKERNEL\n---------\n" >> ${ARTIFACT_OUT_DIR}/${changelog_name}
    kernel_dir=${ANDROID_BUILD_TOP}/kernel/${vendors[0]}/${arch}
    generate_log ${kernel_dir} >> ${ARTIFACT_OUT_DIR}/${changelog_name}

    echo -e "\nDEVICE\n---------\n" >> ${ARTIFACT_OUT_DIR}/${changelog_name}
    device_dir=${ANDROID_BUILD_TOP}/device/${vendors[0]}/${DEVICE_NAME}
    generate_log ${device_dir} >> ${ARTIFACT_OUT_DIR}/${changelog_name}

    echo -e "\nDEVICE-COMMON\n---------\n" >> ${ARTIFACT_OUT_DIR}/${changelog_name}
    generate_log ${common_dir} >> ${ARTIFACT_OUT_DIR}/${changelog_name}

    if [ "x$BUILD_TARGET" == "xotapackage" ]; then
        echo -e "\nVENDOR\n---------\n" >> ${ARTIFACT_OUT_DIR}/${changelog_name}
        vendor_dir=${ANDROID_BUILD_TOP}/vendor/${vendors[0]}
        generate_log ${vendor_dir} >> ${ARTIFACT_OUT_DIR}/${changelog_name}
    fi

    if [ -e ${ANDROID_BUILD_TOP}/CHANGELOG.mkdn ]; then
        echo -e "\n\n---------\n" >> ${ARTIFACT_OUT_DIR}/${changelog_name}
        cat ${ANDROID_BUILD_TOP}/CHANGELOG.mkdn >> ${ARTIFACT_OUT_DIR}/${changelog_name}
    fi
}

