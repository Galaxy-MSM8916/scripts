#!/bin/bash

soc=

SOC_DEVICES_FULL=
SOC_COMPACT_DEVICE_LIST=

newline="
"

function generate_device_list() {

    script_dir=`realpath $(dirname $0)`

    local job_dir="${script_dir}/job_lists"

    [ -z "$SOC_DEVICES_FULL" ] && SOC_DEVICES_FULL=`find $job_dir -name '*txt' | xargs grep DEVICES`

    for i in $SOC_DEVICES_FULL; do
        i=`echo $i | cut -c $(($(echo ${job_dir}|wc -c)+1))-`
        soc=`echo $i | grep -o -e 'msm[0-9a-zA-Z]*'`;
        [ -z "$soc" ] && soc=`echo $i | grep -o -e 'exynos[0-9a-zA-Z]*'`;
        local device_name=`echo $i| cut -d'=' -f 2| cut -d':' -f 1`
        searched_device_name="`echo $SOC_COMPACT_DEVICE_LIST | grep -o $device_name | uniq`"
        if [ "x$searched_device_name" != "x$device_name" ]; then
            SOC_COMPACT_DEVICE_LIST+="$device_name:$soc"
            SOC_COMPACT_DEVICE_LIST+=$newline
        fi
    done
    SOC_COMPACT_DEVICE_LIST=`echo $SOC_COMPACT_DEVICE_LIST | sort | uniq`
}

function find_soc() {

    local device_name=$1

    soc=`echo $SOC_COMPACT_DEVICE_LIST|grep -o ${device_name}:'[a-zA-Z0-9]*'|uniq|cut -d':' -f2`

    # default to msm8916
    [ -z "${soc}" ] && soc=msm8916
    [ -z "${device_name}" ] && soc=msm8916

    echo $soc
}

function print_soc_map() {
    (>&2 echo -e "Arch map is: $SOC_COMPACT_DEVICE_LIST\n")
}

[ -z "$SOC_COMPACT_DEVICE_LIST" ] && generate_device_list
