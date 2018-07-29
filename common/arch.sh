#!/bin/bash

arch=

ARCH_DEVICES_FULL=
ARCH_COMPACT_DEVICE_LIST=

newline="
"

function generate_device_list() {

    script_dir=`realpath $(dirname $0)`

    [ -z $script_dir ] && script_dir="job_lists"

    [ -z "$ARCH_DEVICES_FULL" ] && ARCH_DEVICES_FULL=`find $script_dir -name '*txt' | xargs grep DEVICES`

    for i in $ARCH_DEVICES_FULL; do
	    arch=`echo $i | grep -o -e 'msm[0-9a-zA-Z]*'`;
	    [ -z "$arch" ] && arch=`echo $i | grep -o -e 'exynos[0-9a-zA-Z]*'`;
	    local device_name=`echo $i| cut -d'=' -f 2| cut -d':' -f 1`
	    searched_device_name="`echo $ARCH_COMPACT_DEVICE_LIST | grep -o $device_name | uniq`" 
	    if [ "x$searched_device_name" != "x$device_name" ]; then
	        ARCH_COMPACT_DEVICE_LIST+="$device_name:$arch"
	        ARCH_COMPACT_DEVICE_LIST+=$newline
            fi
    done
    ARCH_COMPACT_DEVICE_LIST=`echo $ARCH_COMPACT_DEVICE_LIST | sort | uniq`
}

function find_arch() {

    local device_name=$1

    [ -z "$ARCH_COMPACT_DEVICE_LIST" ] && generate_device_list

    arch=`echo $ARCH_COMPACT_DEVICE_LIST|grep -o ${device_name}:'[a-zA-Z0-9]*'|uniq|cut -d':' -f2`

    # default to msm8916
    [ -z "${arch}" ] && arch=msm8916
    [ -z "${device_name}" ] && arch=msm8916

    echo $arch
}

function print_arch_map() {
    [ -z "$ARCH_COMPACT_DEVICE_LIST" ] && generate_device_list

    (>&2 echo -e "Arch map is: $ARCH_COMPACT_DEVICE_LIST\n")
}
