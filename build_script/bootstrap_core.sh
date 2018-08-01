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

# declare globals for argv helper
# declare some globals
release_type=""
ver=""
distroTxt=""
recovery_variant=""
recovery_flavour=""

arc_name=""
rec_name=""
bimg_name=""
boot_tar_name=""

chipset=`find_chipset $DEVICE_NAME`
vendor="samsung"

function bootstrap {
    # check repopick tool existence
    repopick_path=`command -v repopick`
    if [ "$?" -ne 0 ] || [ -z "$repopick_path"  ]; then
        PATH=$PATH:${script_path}/tools
    fi

    # check repo existence
    repo_path=`command -v repo`
    if [ "$?" -ne 0 ] || [ -z "$repo_path"  ]; then
        PATH=$PATH:${script_path}/tools
    fi

    export PATH
}

DISTROS="
omni
lineage
lineage-go
cm
rr
AOSPA
dotOS"

if [ -z "$recovery_variant" ]; then
    recovery_variant=$(echo $@ | grep -o 'RECOVERY_VARIANT[ ]*:=[ ]*[A-Za-z0-9]*' | sed s'/ //'g |cut -d':' -f2)
fi

function get_platform_info {
    platform_common_dir="${BUILD_TOP}/device/${vendor}/${chipset}-common/"

    # try to get distribution version from path
    if [ "x$DISTRIBUTION" == "x" ] || [ "x$ver" == "x" ]; then
        for i in ${DISTROS}; do
            if [ `echo $BUILD_TOP | grep -o $i | wc -c` -gt 1 ]; then
                DISTRIBUTION=`echo $BUILD_TOP | grep -o $i`
                ver=`echo $BUILD_TOP |grep $i | cut -d '-' -f 2`
                logr "Guessed distribution is ${DISTRIBUTION} ${ver}"
            fi
        done
    fi

    if [ "x$DISTRIBUTION" == "x" ] || [ "x$ver" == "x" ]; then
        logr "Error: Cannot automatically initialise distribution repo - no distribution specified"
        exit_error 1
    fi

    if ! [ -d "$BUILD_TOP" ] || ! [ -d "$BUILD_TOP/.repo" ]; then

        mkdir $BUILD_TOP

        cd $BUILD_TOP

        echo "Initialising distribution source repo..."
        if [ "x$DISTRIBUTION" == "xlineage" ] ||  [ "x$DISTRIBUTION" == "xlineage-go" ]; then
             if [ "x$ver" == "x14.1" ]; then
                 exit_on_failure repo init -u git://github.com/LineageOS/android.git -b cm-${ver} --depth=1
             else
                 exit_on_failure repo init -u git://github.com/LineageOS/android.git -b lineage-${ver} --depth=1
             fi
        elif [ "x$DISTRIBUTION" == "xrr" ]; then
             exit_on_failure repo init -u https://github.com/ResurrectionRemix/platform_manifest.git -b ${ver} --depth=1
        elif [ "x$DISTRIBUTION" == "xdotOS" ]; then
             exit_on_failure repo init -u git://github.com/DotOS/manifest.git -b dot-${ver} --depth=1
        elif [ "x$DISTRIBUTION" == "xAOSPA" ]; then
	     exit_on_failure repo init -u git://github.com/AOSPA/manifest -b ${ver} --depth=1
        fi

        sync_manifests

        sync_all_old=$SYNC_ALL

        SYNC_ALL=1

        sync_all_trees

        if [ "x$sync_all_old" == "x" ]; then
            SYNC_ALL=
        else
            SYNC_ALL=$sync_all_old
        fi
    fi

    #move into the build dir
    cd $BUILD_TOP

    #get the platform version
    default_plat_version=$(grep 'DEFAULT_PLATFORM_VERSION[ ]*:' build/core/version_defaults.mk|cut -d'=' -f 2 | sed s'/ //'g)
    platform_version=$(grep "PLATFORM_VERSION.${default_plat_version}[ ]*:" build/core/version_defaults.mk|cut -d'=' -f 2)

    if [ "x$platform_version" == "x" ]; then
        platform_version=$(grep 'PLATFORM_VERSION[ ]*:' build/core/version_defaults.mk  | cut -d '=' -f 2)
    fi

    export WITH_SU

    if [ "`echo $platform_version | grep -o "8.1"`" == "8.1" ]; then
        export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4g"
        if [ "x$DISTRIBUTION" == "xlineage" ] || [ "x$DISTRIBUTION" == "xlineage-go" ]; then
            ver="15.1"
            distroTxt="LineageOS"
        elif [ "x$DISTRIBUTION" == "xrr" ]; then
            ver="oreo"
            distroTxt="ResurrectionRemix"
        elif [ "x$DISTRIBUTION" == "xAOSPA" ]; then
            ver="oreo-mr1"
            distroTxt="Paranoid Android"
        fi
    elif [ "`echo $platform_version | grep -o "8.0"`" == "8.0" ]; then
        export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4g"
        if [ "x$DISTRIBUTION" == "xlineage" ]; then
            ver="15.0"
            distroTxt="LineageOS"
        elif [ "x$DISTRIBUTION" == "xrr" ]; then
            ver="oreo"
            distroTxt="ResurrectionRemix"
        elif [ "x$DISTRIBUTION" == "xdotOS" ]; then
            ver="o"
            distroTxt="dotOS"
        fi
    elif [ "`echo $platform_version | grep -o "7.1"`" == "7.1" ]; then
        export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4g"
        if [ "x$DISTRIBUTION" == "xlineage" ]; then
            ver="14.1"
            distroTxt="LineageOS"
        elif [ "x$DISTRIBUTION" == "xrr" ]; then
            ver="5.8"
            distroTxt="ResurrectionRemix"
        elif [ "x$DISTRIBUTION" == "xcm" ]; then
            ver="14.1"
            distroTxt="CyanogenMod"
        elif [ "x$DISTRIBUTION" == "xomni" ]; then
            ver="7.1"
            distroTxt="Omni"
        fi
    elif [ "`echo $platform_version | grep -o "6.0"`" == "6.0" ]; then
        if [ "x$DISTRIBUTION" == "xlineage" ]; then
            ver="13.0"
            distroTxt="LineageOS"
        elif [ "x$DISTRIBUTION" == "xcm" ]; then
            ver="13.0"
            distroTxt="CyanogenMod"
        elif [ "x$DISTRIBUTION" == "xomni" ]; then
            ver="6.0"
            distroTxt="Omni"
        fi
    elif [ "`echo $platform_version | grep -o "5.1"`" == "5.1" ]; then
        if [ "x$DISTRIBUTION" == "xcm" ]; then
            ver="12.1"
            distroTxt="CyanogenMod"
        elif [ "x$DISTRIBUTION" == "xRR" ]; then
            ver="5.6"
            distroTxt="ResurrectionRemix"
        elif [ "x$DISTRIBUTION" == "xomni" ]; then
            ver="5.1"
            distroTxt="Omni"
        fi
    elif [ "`echo $platform_version | grep -o "5.0"`" == "5.0" ]; then
        if [ "x$DISTRIBUTION" == "xcm" ]; then
            ver="12.0"
            distroTxt="CyanogenMod"
        elif [ "x$DISTRIBUTION" == "xomni" ]; then
            ver="5.0"
            distroTxt="Omni"
        fi

    fi

    # print the distribution and platform
    logb "Distro is: ${distroTxt}/${DISTRIBUTION}-${ver} on platform ${platform_version}"

    #set the recovery type
    if [ -z "$recovery_variant" ] && [ -n "$RECOVERY_VARIANT" ]; then
        recovery_variant=$RECOVERY_VARIANT
    fi
    if [ -z "$recovery_variant" ]; then
        recovery_variant=$(grep 'RECOVERY_VARIANT[ ]*:=[ ]*' ${platform_common_dir}/BoardConfigCommon.mk 2>/dev/null | grep -v '#' | sed s'/ //'g |cut -d':' -f2)
    fi
    if [ -z "$recovery_variant" ]; then
        recovery_variant=$(grep 'RECOVERY_VARIANT[ ]*:=[ ]*' ${platform_common_dir}/board/*.mk | grep -v '#' | grep -o 'twrp' | sort | uniq)
    fi
    if [ x`echo ${JOB_NAME} | grep -o 'twrp'` == "xtwrp" ]; then
	recovery_variant="twrp"
    fi
    # get the release type
    if [ "x${release_type}" == "x" ]; then
        release_type=$(grep "CM_BUILDTYPE" ${platform_common_dir}/${DISTRIBUTION}.mk 2>/dev/null | cut -d'=' -f2 | sed s'/ //'g)
    fi

    # check if it was succesfully set, and set it to the default if not
    if [ "x${release_type}" == "x" ]; then
        release_type="NIGHTLY"
    fi

    # get the recovery type
    if [ "$recovery_variant" == "twrp" ] && [ -d "${BUILD_TOP}/bootable/recovery-twrp" ]; then
        export RECOVERY_VARIANT=twrp
        [ -e "${BUILD_TOP}/bootable/recovery/variables.h" ] && TWRP_VAR_FILE="${BUILD_TOP}/bootable/recovery/variables.h"
        [ -e "${BUILD_TOP}/bootable/recovery-twrp/variables.h" ] && TWRP_VAR_FILE="${BUILD_TOP}/bootable/recovery-twrp/variables.h"

        if [ "x${TWRP_VAR_FILE}" != "x" ]; then
            recovery_ver=`cat ${TWRP_VAR_FILE} | grep 'define TW_VERSION_STR' | grep '"' | cut -d '"' -f 2`
            if [ -z "$recovery_ver" ]; then
                recovery_ver=`cat ${TWRP_VAR_FILE} | grep 'define TW_MAIN_VERSION_STR' | grep '"' | cut -d '"' -f 2`
            fi
            recovery_flavour="TWRP-${recovery_ver}"
        elif [ "`echo $ver | grep -o "7.1"`" == "7.1" ]; then
            recovery_flavour="TWRP-3.1.x"
        elif [ "`echo $ver | grep -o "6.0"`" == "6.0" ]; then
            recovery_flavour="TWRP-3.0.x"
        else
            recovery_flavour="TWRP-2.8.7.0"
        fi
    elif [ "x$DISTRIBUTION" == "xlineage" ] || [ "x$DISTRIBUTION" == "xlineage-go" ] || [ "x$DISTRIBUTION" == "xrr" ] || [ "x$DISTRIBUTION" == "xAOSPA" ]; then
        recovery_flavour="LineageOSRecovery"
    elif [ "x$DISTRIBUTION" == "xdotOS" ]; then
        recovery_flavour="dotOSRecovery"
    elif [ "x$DISTRIBUTION" == "xcm" ]; then
        recovery_flavour="CyanogenModRecovery"
    elif [ "x$DISTRIBUTION" == "xomni" ]; then
        if [ "`echo $ver | grep -o "7.1"`" == "7.1" ]; then
            recovery_flavour="TWRP-3.1.x"
        elif [ "`echo $ver | grep -o "6.0"`" == "6.0" ]; then
            recovery_flavour="TWRP-3.0.x"
        else
            recovery_flavour="TWRP-2.8.7.0"
        fi
    fi

    # hack for lineage go naming
    if [ "x`echo ${OUTPUT_DIR} | grep -o 'los-go'`" == "xlos-go" ]; then
        DISTRIBUTION="lineage-go"
    fi

     #define archive naming variables
    if [ "x${JOB_BUILD_NUMBER}" == "x" ]; then
        arc_name=${DISTRIBUTION}-${ver}-$(date +%Y%m%d)-${release_type}-${DEVICE_NAME}
        rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_$(date +%Y%m%d)_${DEVICE_NAME}
        bimg_name=bootimage-${DISTRIBUTION}-${ver}_$(date +%Y%m%d)_${DEVICE_NAME}
        #bimg_name=boot_caf-based_$(date +%Y%m%d)-${DEVICE_NAME}
        boot_tar_name=bootimage_$(date +%Y%m%d)-${DEVICE_NAME}.tar
    else
        arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
        rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
        bimg_name=bootimage-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
        #bimg_name=boot_caf-based_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}
        boot_tar_name=bootimage_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)-${DEVICE_NAME}.tar
    fi

}

function setup_env {

    #move into the build dir
    cd $BUILD_TOP

    #set up the environment
    . build/envsetup.sh

    # remove duplicate crypt_fs.
    if [ -d ${BUILD_TOP}/device/qcom-common/cryptfs_hw ] && [ -d ${BUILD_TOP}/vendor/qcom/opensource/cryptfs_hw ]; then
        rm -r ${BUILD_TOP}/vendor/qcom/opensource/cryptfs_hw
    fi

    #select the device
    lunch ${DISTRIBUTION}_${DEVICE_NAME}-${BUILD_VARIANT}

    if [ "$?" -ne 0 ]; then
	# try lunch as lineage
        if [ "x$DISTRIBUTION" != "xlineage" ] && [ "x$DISTRIBUTION" != "xrr" ]; then
            lunch lineage_${DEVICE_NAME}-${BUILD_VARIANT}
        fi
    fi

    # exit if there was an error
    exit_error $?

    # make the artifact dir
    exit_on_failure mkdir -p $ARTIFACT_OUT_DIR
    exit_on_failure mkdir -p ${SAVED_BUILD_JOBS_DIR}
}
