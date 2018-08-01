#!/bin/bash

chipset=

CHIPSET_DEVICES_FULL=
CHIPSET_COMPACT_DEVICE_LIST=

newline="
"

function generate_device_list() {

    script_dir=`realpath $(dirname $0)`

    [ -z $script_dir ] && script_dir="job_lists"

    [ -z "$CHIPSET_DEVICES_FULL" ] && CHIPSET_DEVICES_FULL=`find $script_dir -name '*txt' | xargs grep DEVICES`

    for i in $CHIPSET_DEVICES_FULL; do
        chipset=`echo $i | grep -o -e 'msm[0-9a-zA-Z]*'`;
        [ -z "$chipset" ] && chipset=`echo $i | grep -o -e 'exynos[0-9a-zA-Z]*'`;
        local device_name=`echo $i| cut -d'=' -f 2| cut -d':' -f 1`
        searched_device_name="`echo $CHIPSET_COMPACT_DEVICE_LIST | grep -o $device_name | uniq`"
        if [ "x$searched_device_name" != "x$device_name" ]; then
            CHIPSET_COMPACT_DEVICE_LIST+="$device_name:$chipset"
            CHIPSET_COMPACT_DEVICE_LIST+=$newline
        fi
    done
    CHIPSET_COMPACT_DEVICE_LIST=`echo $CHIPSET_COMPACT_DEVICE_LIST | sort | uniq`
}

function find_chipset() {

    local device_name=$1

    [ -z "$CHIPSET_COMPACT_DEVICE_LIST" ] && generate_device_list

    chipset=`echo $CHIPSET_COMPACT_DEVICE_LIST|grep -o ${device_name}:'[a-zA-Z0-9]*'|uniq|cut -d':' -f2`

    # default to msm8916
    [ -z "${chipset}" ] && chipset=msm8916
    [ -z "${device_name}" ] && chipset=msm8916

    echo $chipset
}

function print_chipset_map() {
    [ -z "$CHIPSET_COMPACT_DEVICE_LIST" ] && generate_device_list

    (>&2 echo -e "Arch map is: $CHIPSET_COMPACT_DEVICE_LIST\n")
}
