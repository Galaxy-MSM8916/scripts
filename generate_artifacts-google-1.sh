#!/bin/bash

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
    for i in `find /var/www/ -name 'download.*.com'`; do
        rm -rf `find ${i}/public_html -mindepth 1 -type d | grep -v _h5ai`
    done
}

function fix_html_home_perms() {
    for i in `find /var/www/ -name 'download.*.com'`; do
	chmod og+r ${i} -R
    done
}

function link_artifacts() {
# arg1: find_dir  arg2: out_dir arg3: device
    local find_dir=$1
    local out_dir=$2
    local device=$3
    for j in `find $find_dir -mindepth 1 -maxdepth 1 -type f| egrep -iv torrent\|\.part`; do
	    # ! [ -f $DEST/$(basename $j) ] && 
	    #echo "Linking $j --> $DEST/$(basename $j) ..."
	    I_DIR=$(dirname $j)

	    [ -e $out_dir/$(basename $j) ] || ln $j $out_dir/$(basename $j)
	    if [ $? -ne 0 ] && ! [ -e $out_dir/$(basename $j) ]; then
		   ln -s $j $out_dir/$(basename $j)
            fi

	    if [ -e "$I_DIR/$device" ]; then
		    for k in `find "$I_DIR/$device" -type f | egrep -iv torrent\|\.part`; do
			    [ -e "$out_dir/$(basename $k)" ] && ln $k $out_dir
			    [ $? -ne 0 ] && ln -s $k $out_dir
	            done
            fi
    done
}


TRANSMISSION_OUT=/var/lib/transmission-daemon/downloads/
T_OUT=/var/lib/transmission-daemon/.config/transmission-daemon/torrents/
T_BIN=/usr/bin/transmission-remote

if [ -z "$JENKINS_HOME" ]; then
    JENKINS_HOME=/var/lib/jenkins
fi

sanitize_html_home

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

    for i in `find ${T_OUT} -type f -name ${find_regexp}`; do
    #    FILE_NAME=$(basename $i | sed s'/.zip//'g);
        file_name=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
        device_name=$(echo $file_name | cut -d '-' -f ${device_offset})
        build_date=$(echo $file_name | cut -d '_' -f ${date_offset})
        out_dir=`get_html_home $device_name`/${dist_name}/$device_name/$build_date
        mkdir -p $out_dir
        #F_DIR="$(dirname $i)"
        f_dir=${TRANSMISSION_OUT}/${file_name}

        #TORRENT=`find $T_OUT/ -name "$FILE_NAME"'*torrent'`
        torrent=$i
        dest_torrent="$out_dir/${file_name}.torrent"

        link_artifacts $f_dir $out_dir $device_name

        if ! [ -e $dest_torrent ] && [ -f $torrent ]; then
        ln $torrent $dest_torrent;
        fi
    #    echo
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


    for i in `find /var/www/ -name 'download.*.com'`; do
        echo "Copying zip ${zram_zip} to ${i} ..."
	mkdir -p $i/public_html/ZRAM
        cp ${zram_zip} $i/public_html/ZRAM
    done

    rm -rf $temp_dir
}

for i in `find ${T_OUT} -type f -name 'TWRP*'`; do
#    FILE_NAME=$(basename $i | sed s'/.zip//'g);
#    FILE_NAME=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
    FILE_NAME=$(basename $i | sed s'/\.tar\.[a-z0-9]*\.torrent//'g);
    DEVICE=$(echo $FILE_NAME | cut -d '_' -f 4)
    VERSION=$(echo $FILE_NAME | cut -d '-' -f 2)
    DATE=$(echo $FILE_NAME | cut -d '_' -f 3)
    OUT_DIR=`get_html_home $DEVICE`/TWRP/$VERSION/$DEVICE/$DATE/
    TORRENT=$i
    TAR=$TRANSMISSION_OUT/${FILE_NAME}.tar
    DEST_TORRENT="$OUT_DIR/${FILE_NAME}.torrent"

    mkdir -p $OUT_DIR

    if ! [ -e $OUT_DIR/${FILE_NAME}.tar ] && [ -f $TAR ]; then
	ln $TAR $OUT_DIR/${FILE_NAME}.tar
	#chmod og+r $OUT_DIR/${FILE_NAME}.tar
    fi

    if ! [ -e $DEST_TORRENT ] && [ -f $TORRENT ]; then
        ln $TORRENT $DEST_TORRENT;
	#chmod og+r $DEST_TORRENT
    fi
#    echo
done

# TODO: Generate for all chipsets
for i in `find ${T_OUT} -type f -name 'open_gapps*'`; do
#    FILE_NAME=$(basename $i | sed s'/.zip//'g);
#    FILE_NAME=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
    FILE_NAME=$(basename $i | sed s'/\.zip\.[a-z0-9]*\.torrent//'g);
    VERSION=$(echo $FILE_NAME | cut -d '-' -f 3)
    DATE=$(echo $FILE_NAME | cut -d '-' -f 5)
    OUT_DIR=`get_html_home $DEVICE`/OpenGApps/$VERSION/$DATE/
    TORRENT=$i
    ZIP=$TRANSMISSION_OUT/${FILE_NAME}.zip
    DEST_TORRENT="$OUT_DIR/${FILE_NAME}.torrent"

#    TORRENT=`find $T_OUT/ -name "$FILE_NAME"'*torrent'`

    mkdir -p $OUT_DIR

    if ! [ -e $OUT_DIR/${FILE_NAME}.zip ] && [ -f $ZIP ]; then
	ln $ZIP $OUT_DIR/${FILE_NAME}.zip
	#chmod og+r $OUT_DIR/${FILE_NAME}.zip
    fi

    if ! [ -e $DEST_TORRENT ] && [ -f $TORRENT ]; then
        ln $TORRENT $DEST_TORRENT;
	#chmod og+r $DEST_TORRENT
    fi
#    echo
done

for i in `find ${T_OUT} -type f -name 'rr*torrent'`; do
#    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    FILE_NAME=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
    DEVICE_NAME=$(echo $FILE_NAME | cut -d '-' -f 3)
    BUILD_DATE=$(echo $FILE_NAME | cut -d '_' -f 3)
    OUT_DIR=`get_html_home $DEVICE_NAME`/ResurrectionRemix/$DEVICE_NAME/$BUILD_DATE
    mkdir -p $OUT_DIR
#    F_DIR="$(dirname $i)"
    F_DIR=${TRANSMISSION_OUT}/${FILE_NAME}

#    TORRENT=`find $T_OUT/ -name "$FILE_NAME"'*torrent'`
    TORRENT=$i
    DEST_TORRENT="$OUT_DIR/${FILE_NAME}.torrent"

    link_artifacts $F_DIR $OUT_DIR $DEVICE_NAME

    if ! [ -e $DEST_TORRENT ] && [ -f $TORRENT ]; then
        ln $TORRENT $DEST_TORRENT;
#	chmod og+r $DEST_TORRENT
    fi
#    echo
done

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
