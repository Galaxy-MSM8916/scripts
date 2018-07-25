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

function acquire_build_lock {

    local lock_name="android_build_lock"
    local lock="/var/lock/${lock_name}"

    exec 200>${lock}

    echoTextBlue "Attempting to acquire lock $lock..."

    # loop if we can't get the lock
    while true; do
        flock -n 200
        if [ $? -eq 0 ]; then
            break
        else
            printf "%c" "."
            sleep 5
        fi
    done

    # set the pid
    pid=$$
    echo ${pid} 1>&200

    echoTextBlue "Lock ${lock} acquired. PID is ${pid}"
}

function remove_build_lock {
    echoText "Removing lock..."
    exec 200>&-
}

function clean_out {
    cd $BUILD_TOP/
    if [ "x${CLEAN_TARGET_OUT}" != "x" ] && [ ${CLEAN_TARGET_OUT} -eq 1 ]; then
        echoText "Cleaning build dir..."
        rm -rf out
    fi
}

function remove_temp_dir {
    #start cleaning up
    echoText "Removing temp dir..."
    rm -rf $BUILD_TEMP
}

function exit_on_failure {
    echoTextBlue "Running command: $@"
    $@
    exit_error $?
}


function exit_error {
    if [ "x$1" != "x0" ]; then
        echoText "Error encountered, aborting..."
        if [ "x$SILENT" != "x1" ]; then
            END_TIME=$( date +%s )
            buildTime="%0A%0ABuild time: $(format_time ${END_TIME} ${BUILD_START_TIME})"
            totalTime="%0ATotal time: $(format_time ${END_TIME} ${START_TIME})"

            if [ "x$JOB_DESCRIPTION" != "x" ]; then
                textStr="$JOB_DESCRIPTION, build %23${JOB_BUILD_NUMBER}"
            else
                textStr="${distroTxt} ${ver} ${BUILD_TARGET} for the ${DEVICE_NAME}"
            fi

            textStr+=" aborted."

            textStr+="%0A%0AThis build was running on ${USER}@${HOSTNAME}."

            if [ "x${JOB_URL}" != "x" ]; then
                textStr+="%0A%0AYou can see the build log at:"
                textStr+="%0A${JOB_URL}/console"
            fi

            textStr+="${buildTime}${totalTime}"

            if [ "x$PRINT_VIA_PROXY" != "x" ] && [ "x$SYNC_HOST" != "x" ]; then
                timeout -s 9 20 ssh $SYNC_HOST wget \'"https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=$textStr"\' -O - > /dev/null 2>/dev/null
            else

                timeout -s 9 10 wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=$textStr" -O - > /dev/null 2>/dev/null
            fi
        fi
        remove_temp_dir
        remove_build_lock
        exit 1
    fi
}

# PRINTS A FORMATTED HEADER TO POINT OUT WHAT IS BEING DONE TO THE USER
function echoText() {
    echoTextRed "$@"
}

function echoTextRed() {
    echo -e ${RED}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextBlue() {
    echo -e ${BLUE}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextGreen() {
    echo -e ${GREEN}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextBold() {
    echo -e ${BOLD}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

# FORMATS THE TIME
function format_time() {
    MINS=$(((${1}-${2})/60))
    SECS=$(((${1}-${2})%60))
    if [[ ${MINS} -ge 60 ]]; then
        HOURS=$((${MINS}/60))
        MINS=$((${MINS}%60))
    fi

    if [[ ${HOURS} -eq 1 ]]; then
        TIME_STRING+="1 hour, "
    elif [[ ${HOURS} -ge 2 ]]; then
        TIME_STRING+="${HOURS} hours, "
    fi

    if [[ ${MINS} -eq 1 ]]; then
        TIME_STRING+="1 minute"
    else
        TIME_STRING+="${MINS} minutes"
    fi

    if [[ ${SECS} -eq 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", and 1 second"
    elif [[ ${SECS} -eq 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" and 1 second"
    elif [[ ${SECS} -ne 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", and ${SECS} seconds"
    elif [[ ${SECS} -ne 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" and ${SECS} seconds"
    fi

    echo ${TIME_STRING}
}

# CREATES A NEW LINE IN TERMINAL
function newLine() {
    echo -e ""
}

# PRINTS AN ERROR IN BOLD RED
function reportError() {
    RED="\033[01;31m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${RED}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}

devices=
devices_full=
job_search_path=${BUILD_TEMP}/jenkins_jobs

newline="
"

function update_job_repo() {
    update_file=$job_search_path/.updated
    if ! [ -d $job_search_path ]; then
        git clone http://git.msm8916.com/Galaxy-MSM8916/jenkins_job_generation_script.git/ $job_search_path
    elif [ "`find $update_file -mtime 0`" != "$update_file" ]; then
        git -C $job_search_path pull
        touch $update_file
    fi
}

function generate_device_list() {
    [ -d "$job_search_path" ] || (>&2 update_job_repo)
    [ -z $devices_full ] && devices_full=`find $job_search_path -name '*txt' | xargs grep DEVICES`

    for i in $devices_full; do
	    arch=`echo $i | grep -o -e 'msm[0-9a-zA-Z]*'`;
	    [ -z $arch ] && arch=`echo $i | grep -o -e 'exynos[0-9a-zA-Z]*'`;
	    device=`echo $i| cut -d'=' -f 2| cut -d':' -f 1`
	    if [ "`echo $devices | grep -o $device | uniq`" != "$device" ]; then
	        devices+="$device:$arch"
	        devices+=$newline
            fi
    done
    devices=`echo $devices | sort | uniq`
}

function find_arch() {

    [ -z $devices ] && generate_device_list

    arch=`echo $devices|grep -o ${DEVICE_NAME}:'[a-zA-Z0-9]*'|uniq|cut -d':' -f2`

    # default to msm8916
    [ -z ${DEVICE_NAME} ] && arch=msm8916
    [ -z $arch ] && arch=msm8916

    echo $arch && (>&2 echo -e "Arch of device ${DEVICE_NAME} is: $arch\n\nArch map is: $devices\n\n")
}

