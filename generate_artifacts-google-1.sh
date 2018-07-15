#!/bin/bash

search_path="/home/vincent/jenkins_job_generation_script"
devices=
devices_full=

newline="
"

function update_job_repo() {
    update_file=$search_path/.updated
    if ! [ -d $search_path ]; then
        git clone https://git.msm8953.com/Galaxy-MSM8916/jenkins_job_generation_script.git/ $search_path
    elif [ "`find $update_file -mtime 0`" != "$update_file" ]; then
        git -C $search_path pull
        touch $update_file
    fi
}

function optimise_device_list() {
    [ -d "$search_path" ] || (>&2 update_job_repo)
    [ -z $devices_full ] && devices_full=`find $search_path -name '*txt' | xargs grep DEVICES`

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
    device=$1

    #arch=`for i in $devices_full; do echo $i|grep $device; done|grep -o -e 'msm[0-9a-zA-Z]*'|sort|uniq`

    arch=`echo $devices|grep -o $device:'[a-zA-Z0-9]*'|uniq|cut -d':' -f2`

    echo $arch #&& (>&2 echo "Arch of device $device is: $arch")
}

function get_html_home() {
# first arg - device name
    local arch=`find_arch $1`

    [ -z $arch ] && arch=msm8916

    echo /var/www/download.${arch}.com/public_html
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
update_job_repo
optimise_device_list

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

# TODO: Generate for all archs
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

for i in `find ${T_OUT} -type f -name 'lineage-1*torrent'`; do
#    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    FILE_NAME=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
    DEVICE_NAME=$(echo $FILE_NAME | cut -d '-' -f 3)
    BUILD_DATE=$(echo $FILE_NAME | cut -d '_' -f 3)
    OUT_DIR=`get_html_home $DEVICE_NAME`/LineageOS/$DEVICE_NAME/$BUILD_DATE
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

for i in `find ${T_OUT} -type f -name 'lineage-go-1*torrent'`; do
#    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    FILE_NAME=$(basename $i | sed s'/\.[a-z0-9]*\.torrent//'g);
    DEVICE_NAME=$(echo $FILE_NAME | cut -d '-' -f 4)
    BUILD_DATE=$(echo $FILE_NAME | cut -d '_' -f 3)
    OUT_DIR=`get_html_home $DEVICE_NAME`/LineageOS_Go/$DEVICE_NAME/$BUILD_DATE
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

fix_html_home_perms
