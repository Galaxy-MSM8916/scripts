#!/bin/bash

TRANSMISSION_DOWNLOAD_SOURCE=/var/lib/transmission-daemon/downloads/
TORRENT_SOURCE_DIR=/var/lib/transmission-daemon/.config/transmission-daemon/torrents/

# source 'script' functions
. $(dirname $0)/common/source.sh
# source common scripts
source_common

# update the repo
update_repo

function get_html_home() {
    # first arg - device name
    local chipset=`find_chipset $1`
    echo /var/www/download.${chipset}.com/public_html
}

function sanitize_html_home() {
    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        rm -rf `find ${doc_root}/public_html -mindepth 1 -type d | grep -v _h5ai`
    done
}

function fix_html_home_perms() {
    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        chmod og+r ${doc_root} -R
    done
}

function link_artifacts() {
    # arg1: find_dir  arg2: html_out_dir arg3: device
    local find_dir=$1
    local html_out_dir=$2
    local device=$3
    for j in `find $find_dir -mindepth 1 -maxdepth 1 -type f| egrep -iv torrent\|\.part`; do
        # ! [ -f $DEST/$(basename $j) ] &&
        #echo "Linking $j --> $DEST/$(basename $j) ..."
        I_DIR=$(dirname $j)

        [ -e $html_out_dir/$(basename $j) ] || ln $j $html_out_dir/$(basename $j)
        if [ $? -ne 0 ] && ! [ -e $html_out_dir/$(basename $j) ]; then
            ln -s $j $html_out_dir/$(basename $j)
        fi

        if [ -e "$I_DIR/$device" ]; then
            for k in `find "$I_DIR/$device" -type f | egrep -iv torrent\|\.part`; do
                [ -e "$html_out_dir/$(basename $k)" ] && ln $k $html_out_dir
                [ $? -ne 0 ] && ln -s $k $html_out_dir
            done
        fi
    done
}

function generate_artifacts_from_torrent() {
    # arg1: find regexp; arg2: dist long (dir) name
    # arg3: device name offset; arg4: build date offset
    local find_regexp=$1
    local dist_name=$2
    local device_offset=$3
    local date_offset=$4

    # set some reasonable defaults
    [ -z "$device_offset" ] && device_offset='3'
    [ -z "$date_offset" ] && date_offset='3'

    for source_torrent in `find ${TORRENT_SOURCE_DIR} -type f -name ${find_regexp}`; do
        file_name=$(basename $source_torrent | sed s'/\.[a-z0-9]*\.torrent//'g);
        device_name=$(echo $file_name | cut -d '-' -f ${device_offset})
        build_date=$(echo $file_name | cut -d '_' -f ${date_offset})
        html_out_dir=`get_html_home $device_name`/${dist_name}/$device_name/$build_date
        mkdir -p $html_out_dir
        transmission_out_dir=${TRANSMISSION_DOWNLOAD_SOURCE}/${file_name}

        dest_torrent="$html_out_dir/${file_name}.torrent"

        link_artifacts $transmission_out_dir $html_out_dir $device_name

        if ! [ -e $dest_torrent ] && [ -f $source_torrent ]; then
            ln $source_torrent $dest_torrent;
        fi
        #echo
    done
}

function generate_zram_zip() {
    #arg1: size (in MiB)

    local zram_size=$1

    local temp_dir=$(mktemp -d)
    local zip_basename="enable_zram_${zram_size}MiB"
    local zip_dir=${temp_dir}/${zip_basename}
    local zram_zip="${temp_dir}/enable_zram_${zram_size}MiB.zip"

    local binary_target_dir=META-INF/com/google/android
    local install_target_dir=install/bin
    local blob_dir=blobs
    local proprietary_dir=proprietary

    mkdir -p ${zip_dir}/${binary_target_dir}
    mkdir -p ${zip_dir}/${blob_dir}
    mkdir -p ${zip_dir}/${proprietary_dir}
    mkdir -p ${zip_dir}/${install_target_dir}/installbegin
    mkdir -p ${zip_dir}/${install_target_dir}/installend
    mkdir -p ${zip_dir}/${install_target_dir}/postvalidate

    # copy scripts
    cp ${script_dir}/templates/enable_zram.sh ${zip_dir}/${install_target_dir}/installbegin
    cp ${script_dir}/templates/functions.sh ${zip_dir}/${install_target_dir}/
    cp ${script_dir}/templates/run_scripts.sh ${zip_dir}/${install_target_dir}/
    cp ${script_dir}/templates/updater-script ${zip_dir}/${binary_target_dir}/
    cp ${script_dir}/updater/update-binary ${zip_dir}/${binary_target_dir}

    # replace placeholders in template
    sed -i s/\#\#zram_size/${zram_size}/g ${zip_dir}/${install_target_dir}/installbegin/enable_zram.sh

    #archive the image
    echo "Creating zip ${zram_zip}..."
    cd ${zip_dir} && zip ${zram_zip} `find ${zip_dir} -type f | cut -c $(($(echo ${zip_dir}|wc -c)+1))-`


    for doc_root in `find /var/www/ -name 'download.*.com'`; do
        echo "Copying zip ${zram_zip} to ${doc_root} ..."
        mkdir -p $doc_root/public_html/ZRAM
        cp ${zram_zip} $doc_root/public_html/ZRAM
    done

    rm -rf $temp_dir
}

# clear old artifacts
sanitize_html_home

function generate_twrp_artifacts() {
    for source_torrent in `find ${TORRENT_SOURCE_DIR} -type f -name 'TWRP*'`; do
        file_name=$(basename $source_torrent | sed s'/\.tar\.[a-z0-9]*\.torrent//'g);
        device=$(echo $file_name | cut -d '_' -f 4)
        version=$(echo $file_name | cut -d '-' -f 2)
        date=$(echo $file_name | cut -d '_' -f 3)
        html_out_dir=`get_html_home $device`/TWRP/$version/$device/$date/
        twrp_source_tar=${TRANSMISSION_DOWNLOAD_SOURCE}/${file_name}.tar
        dest_torrent="$html_out_dir/${file_name}.torrent"

        mkdir -p $html_out_dir

        if ! [ -e $html_out_dir/${file_name}.tar ] && [ -f $twrp_source_tar ]; then
            ln $twrp_source_tar $html_out_dir/${file_name}.tar
        fi

        if ! [ -e $dest_torrent ] && [ -f $source_torrent ]; then
            ln $source_torrent $dest_torrent;
        fi
    done
}

function generate_gapps_artifacts() {
    # TODO: Generate for all chipsets
    for source_torrent in `find ${TORRENT_SOURCE_DIR} -type f -name 'open_gapps*'`; do
        file_name=$(basename $source_torrent | sed s'/\.zip\.[a-z0-9]*\.torrent//'g);
        version=$(echo $file_name | cut -d '-' -f 3)
        date=$(echo $file_name | cut -d '-' -f 5)
        html_out_dir=`get_html_home $device`/OpenGApps/$version/$date/
        source_zip=${TRANSMISSION_DOWNLOAD_SOURCE}/${file_name}.zip
        dest_torrent="$html_out_dir/${file_name}.torrent"

        mkdir -p $html_out_dir

        if ! [ -e $html_out_dir/${file_name}.zip ] && [ -f $source_zip ]; then
            ln $source_zip $html_out_dir/${file_name}.zip
        fi

        if ! [ -e $dest_torrent ] && [ -f $source_torrent ]; then
            ln $source_torrent $dest_torrent;
        fi
    done
}

generate_twrp_artifacts
generate_gapps_artifacts

generate_artifacts_from_torrent 'rr*torrent' "ResurrectionRemix" 3 3
generate_artifacts_from_torrent 'lineage-1*torrent' "LineageOS" 3 3
generate_artifacts_from_torrent 'lineage-go-1*torrent' "LineageOS_Go" 4 3

zram_lower=256
zram_incr=128
zram_upper=1024

# generate zram images
for size in `seq $zram_lower $zram_incr $zram_upper`; do
    generate_zram_zip $size
done

fix_html_home_perms
