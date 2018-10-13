#!/bin/bash

# source 'script' functions
. $(dirname $0)/common/source.sh
# source common scripts
source_common

# update the repo
update_repo

TAG_LIST=""

function get_html_home() {
    # first arg - device name
    local soc=`find_soc $1`
    echo /var/www/download.${soc}.com/public_html
}

function sanitize_html_home() {
    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        rm -rf `find ${doc_root}/public_html -mindepth 1 -type d | grep -v _h5ai`
    done
}

function restore_h5ai() {
    if [ -f $script_dir/h5ai.zip ]; then
        for doc_root in `find /var/www/ -name 'download.*.com'`; do
            [ -d $doc_root/public_html/_h5ai ] || unzip $script_dir/h5ai.zip -d $doc_root/public_html/
        done
    fi
}

function fix_html_home_perms() {
    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        chmod og+r ${doc_root} -R
    done
}

function generate_index_php() {
# arg1: redirect url
echo "<?php
header(\"Location: $1\");
die();
?>
"
}

function get_releases() {

    if [ "x$TAG_LIST" == "x" ]; then
        socs="msm8916 msm8953"
        for soc in $socs; do
            # clone the tree
            repo=`mktemp -d`
            git clone https://github.com/Galaxy-${soc^^}/releases $repo 2>/dev/null
            [ "$?" -ne 0 ] && git clone https://review.${soc}.com/Galaxy-MSM8916/releases $repo 2>/dev/null

            # get the tags
            git -C $repo fetch origin refs/tags/*:refs/tags/*

            TAG_LIST+=" `git -C $repo show-ref --tags|grep -iv Gapps|grep -v ZRAM | less|cut -d '/' -f3`"
            rm -rf $repo
        done
    fi

    echo $TAG_LIST|sed s'/ /\n/'g|sort|uniq
}

function generate_releases_from_tags() {
    # arg1: find regexp
    # arg2: dist long (dir) name
    # arg3: sed underscores to dashes
    # arg4: version offset
    # arg5:device name offset;
    # arg6: build date offset
    local find_regexp=$1
    local dist_name=$2
    local sed_underscores=$3
    local version_offset=$4
    local device_offset=$5
    local date_offset=$6

    # set some reasonable defaults
    [ -z "$version_offset" ] && version_offset='2'
    [ -z "$device_offset" ] && device_offset='3'
    [ -z "$date_offset" ] && date_offset='3'

    for source_tag in `get_releases|grep "${find_regexp}"`; do
        file_name=$(basename $source_tag | sed s'/\.[a-z0-9]*\.torrent//'g);
        [ "$sed_underscores" -eq 1 ] && file_name_std=$(echo $file_name|sed s'/_/-/'g) || file_name_std=$file_name
        version=$(echo $file_name_std | cut -d '-' -f ${version_offset})
        device_name=$(echo $file_name_std | cut -d '-' -f ${device_offset})
        build_date=$(echo $file_name_std | cut -d '-' -f ${date_offset})
        html_out_dir=`get_html_home $device_name`/${dist_name}/$version/$device_name/$build_date
        mkdir -p $html_out_dir

        generate_index_php "https://github.com/Galaxy-${soc^^}/releases/releases/tag/${file_name}" >> $html_out_dir/index.php
    done
}

function generate_gapps_releases() {
    # e. - MindTheGapps-8.1.0-arm-20180813_031926.zip
    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        html_out_dir=${doc_root}/public_html/MindTheGapps/
        mkdir -p $html_out_dir
        generate_index_php "https://github.com/Galaxy-MSM8916/releases/releases/tag/MindTheGapps" >> $html_out_dir/index.php

        html_out_dir=${doc_root}/public_html/OpenGApps/
        mkdir -p $html_out_dir
        generate_index_php "https://github.com/Galaxy-MSM8916/releases/releases/tag/OpenGApps" >> $html_out_dir/index.php
    done
}

# clear old artifacts
sanitize_html_home
restore_h5ai

generate_gapps_releases

generate_releases_from_tags '^TWRP' "TWRP" 1 2 7 6
generate_releases_from_tags '^dot' "DotOS" 1 2 6 4
generate_releases_from_tags '^oc_hotplug' "Kernels" 0 1 7 6
generate_releases_from_tags '^rr-' "ResurrectionRemix" 1 2 6 4
generate_releases_from_tags '^lineage-1' "LineageOS" 1 2 6 4
generate_releases_from_tags '^lineage-go-1' "LineageOS_Go" 1 3 7 5

for doc_root in `find /var/www/ -name 'download.*.com'`; do
    mkdir -p $doc_root/public_html/ZRAM
    generate_index_php "https://github.com/Galaxy-MSM8916/releases/releases/tag/ZRAM" >> $doc_root/public_html/ZRAM/index.php
done

fix_html_home_perms
