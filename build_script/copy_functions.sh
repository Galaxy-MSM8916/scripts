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

function rsync_cp {
    sync_count=1
    if [ "x${SYNC_HOST}" == "x" ]; then
        remote_mkdir $(dirname $2)
        exit_on_failure rsync -av --append-verify -P $1 $2
    else
        remote_mkdir $(dirname $2)
        echoTextBlue "Using rsync to copy $1 -> ${SYNC_HOST}:$2"
        rsync -av --append-verify -P -e 'ssh -o StrictHostKeyChecking=no' $1 ${SYNC_HOST}:$2

        sync_exit_error=$?

        while [ $sync_exit_error -ne 0 ] && [ $sync_count -le $UPLOAD_RETRY_COUNT ]; do
            echoTextRed "[${sync_count}/${UPLOAD_RETRY_COUNT}] Retrying copy of $1 -> ${SYNC_HOST}:$2"
            rsync -av --append-verify -P -e 'ssh -o StrictHostKeyChecking=no' $1 ${SYNC_HOST}:$2
            sync_exit_error=$?
            sync_count=$((sync_count+1))
        done

        exit_error $sync_exit_error
    fi
}

function remote_mkdir {
    if [ "x${1}" != "x" ]; then
        if [ "x${SYNC_HOST}" != "x" ]; then
            exit_on_failure ssh -o StrictHostKeyChecking=no ${SYNC_HOST} mkdir -p $1
        else
            exit_on_failure mkdir -p $1
        fi
    fi
}

function copy_bootimage {
    if [ "x$BUILD_TARGET" == "xbootimage" ] && [ "x$NO_PACK_BOOTIMAGE" == "x" ]; then
        boot_pkg_dir=${BUILD_TEMP}/boot_pkg
        if [ "x$DISTRIBUTION" == "xlineage" ] || [ "x$DISTRIBUTION" == "xrr" ]; then
            boot_pkg_zip=${ARTIFACT_OUT_DIR}/boot_caf-based_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}.zip
        else
            boot_pkg_zip=${ARTIFACT_OUT_DIR}/boot_aosp-based_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}.zip
        fi

        boot_tar_name=bootimage_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}.tar

        revert_pkg_dir=${BUILD_TEMP}/boot_pkg_revert
        revert_zip=${ARTIFACT_OUT_DIR}/revert_boot_image_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}.zip
        binary_target_dir=META-INF/com/google/android
        install_target_dir=install/bin
        blob_dir=blobs
        proprietary_dir=proprietary

        # create odin package
        echoTextBlue "Creating ODIN-Flashable boot image..."
        tar -C ${ANDROID_PRODUCT_OUT}/ boot.img -c -f ${ARTIFACT_OUT_DIR}/${boot_tar_name}

        # create the directories
        exit_on_failure mkdir -p ${boot_pkg_dir}/${binary_target_dir}
        exit_on_failure mkdir -p ${boot_pkg_dir}/${blob_dir}
        exit_on_failure mkdir -p ${boot_pkg_dir}/${proprietary_dir}
        exit_on_failure mkdir -p ${boot_pkg_dir}/${install_target_dir}/installbegin
        exit_on_failure mkdir -p ${boot_pkg_dir}/${install_target_dir}/installend
        exit_on_failure mkdir -p ${boot_pkg_dir}/${install_target_dir}/postvalidate
        exit_on_failure mkdir -p ${revert_pkg_dir}/${binary_target_dir}
        exit_on_failure mkdir -p ${revert_pkg_dir}/${blob_dir}
        exit_on_failure mkdir -p ${revert_pkg_dir}/${proprietary_dir}
        exit_on_failure mkdir -p ${revert_pkg_dir}/${install_target_dir}/installbegin
        exit_on_failure mkdir -p ${revert_pkg_dir}/${install_target_dir}/installend
        exit_on_failure mkdir -p ${revert_pkg_dir}/${install_target_dir}/postvalidate


        # download the update binary
        echoTextBlue "Fetching update binary..."
        ${CURL} ${SCRIPT_REPO_URL}/updater/update-binary 1>${BUILD_TEMP}/update-binary 2>/dev/null
        cp ${BUILD_TEMP}/update-binary ${revert_pkg_dir}/${binary_target_dir}

        echoTextBlue "Fetching mkbootimg..."
        ${CURL} ${SCRIPT_REPO_URL}/bootimg-tools/mkbootimg 1>${BUILD_TEMP}/mkbootimg 2>/dev/null

        echoTextBlue "Fetching unpackbootimg..."
        ${CURL} ${SCRIPT_REPO_URL}/bootimg-tools/unpackbootimg 1>${BUILD_TEMP}/unpackbootimg 2>/dev/null


        cp ${ANDROID_PRODUCT_OUT}/boot.img ${boot_pkg_dir}/${blob_dir}
        cp ${BUILD_TEMP}/update-binary ${boot_pkg_dir}/${binary_target_dir}
        cp ${BUILD_TEMP}/mkbootimg ${boot_pkg_dir}/${install_target_dir}
        cp ${BUILD_TEMP}/unpackbootimg ${boot_pkg_dir}/${install_target_dir}

        # Create the scripts
        create_scripts

        #archive the image
        echoTextBlue "Creating flashables..."
        cd ${boot_pkg_dir} && zip ${boot_pkg_zip} `find ${boot_pkg_dir} -type f | cut -c $(($(echo ${boot_pkg_dir}|wc -c)+1))-`
        cd ${revert_pkg_dir} && zip ${revert_zip} `find ${revert_pkg_dir} -type f | cut -c $(($(echo ${revert_pkg_dir}|wc -c)+1))-`
    fi
}

function copy_recoveryimage {
    if [ "x$BUILD_TARGET" == "xrecoveryimage" ] || [ "x$BUILD_TARGET" == "xotapackage" ]; then
        if [ -e ${ANDROID_PRODUCT_OUT}/recovery.img ]; then
            #define some variables
            if [ -z ${JOB_BUILD_NUMBER} ]; then
                rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}-$(date +%Y%m%d)-${DEVICE_NAME}
            else
                rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
            fi

            logb "\n\t\tCopying recovery image...\n"
            tar -C ${ANDROID_PRODUCT_OUT}/ recovery.img -c -f ${ARTIFACT_OUT_DIR}/${rec_name}.tar
        fi
    fi
}

function copy_otapackage {
    if [ "x$BUILD_TARGET" == "xotapackage" ]; then
        OTA_REGEXP='*'"${DEVICE_NAME}"'*'"${BUILD_NUMBER}"'*zip'
        logb "\nSearching for OTA package..."
        OTA_FILE=`find ${ANDROID_PRODUCT_OUT} -maxdepth 1 -type f -name ${OTA_REGEXP} 2>/dev/null | head -1 2>/dev/null`

        if ! [ -e "$OTA_FILE" ]; then
            echoText "Failed to find ota package!!"
        else
            echoTextBlue "Found ota package $OTA_FILE"

            #copy the zip in the background
            logb "\n\t\tCopying zip image..."
            cp ${OTA_FILE} ${ARTIFACT_OUT_DIR}/${arc_name}.zip

            if [ "x$ver" == "x15.0" ] || [ "x$ver" == "x15.1" ]; then
                logb "\n\t\tCopying system prop..."
                prop=${ANDROID_PRODUCT_OUT}/system/build.prop
                [ -e ${prop} ] && cp ${prop} ${ARTIFACT_OUT_DIR}/${arc_name}.zip.prop
            fi

            #calculate md5sums
            md5sums=$(md5sum ${OTA_FILE} | cut -d " " -f 1)
            echo "${md5sums} ${arc_name}.zip" > ${ARTIFACT_OUT_DIR}/${arc_name}.zip.md5 || exit_error 1
        fi
    fi
}

COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_bootimage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_recoveryimage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_otapackage")

function copy_files {
    for ix in `seq 0 $((${#COPY_FUNCTIONS[@]}-1))`; do
        echoTextBlue "Running function ${COPY_FUNCTIONS[$ix]}"
        ${COPY_FUNCTIONS[$ix]} $@
    done
}

function upload_artifacts {
    echoTextBlue "Transferring build artifacts..."
    remote_mkdir ${OUTPUT_DIR}
    rsync_cp ${ARTIFACT_OUT_DIR} ${OUTPUT_DIR}
}
