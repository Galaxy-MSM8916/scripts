#!/bin/bash

# source 'script' functions
. common/source.sh
# source common scripts
source_common

# update the repo
update_repo

HTML_HOME=/var/www/download.msm8916.com/public_html
# | grep -v 'los-15'
#TRACKERS="http://tracker.msm8916.com:6969/announce,udp://tracker.coppersurfer.tk:6969,udp://tracker.leechers-paradise.org:6969"
TRACKERS="http://tracker-1.msm8916.com:6969/announce,http://tracker-2.msm8916.com:6969/announce"
T_BIN=/usr/bin/transmission-remote
TRANSMISSION_OUT=/var/lib/transmission-daemon/downloads/

TORRENT_HOSTS="
jenkins.msm8916.com
google-1.msm8916.com
"
#tracker.msm8916.com

if [ -z "$JENKINS_HOME" ]; then
	JENKINS_HOME=$HOME
fi

if [ -z "$TRANSMISSION_USERNAME" ]; then
	TRANSMISSION_USERNAME="transmission"
fi

#acquire_build_lock

for i in `find ${JENKINS_HOME}/jobs/TWRP_Builds -type f -name 'TWRP*.tar'`; do
    FILE_NAME=$(basename $i | sed s'/.tar//'g);
    F_DIR="$(dirname $i)"
    TORRENT="$(dirname $i)/${FILE_NAME}.torrent"

    [ -e $TRANSMISSION_OUT/${FILE_NAME}.tar ] || ln $i $TRANSMISSION_OUT || ln -s $i $TRANSMISSION_OUT

    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -o $TORRENT $F_DIR/${FILE_NAME}.tar

        for host in $TORRENT_HOSTS; do
            [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
        done
    fi
done

for i in `find ${JENKINS_HOME}/jobs/GApps -type f -name '*.zip'`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="$(dirname $i)/${FILE_NAME}.torrent"

    [ -e $TRANSMISSION_OUT/${FILE_NAME}.zip ] || ln $i $TRANSMISSION_OUT || ln -s $i $TRANSMISSION_OUT

    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -o $TORRENT $F_DIR/${FILE_NAME}.zip

        for host in $TORRENT_HOSTS; do
            [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
        done
    fi

done

for i in `find ${JENKINS_HOME}/jobs/AOSPA_Builds -type f -name '*zip' | grep -i aospa | grep -v boot`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="${F_DIR}/${FILE_NAME}.torrent"
    DEST=$TRANSMISSION_OUT/$FILE_NAME

     [ -e $DEST ] || mkdir -p $DEST

     for j in `find $F_DIR -mindepth 1 -maxdepth 1 -type f | grep -iv torrent`; do
         ! [ -f $DEST/$(basename $j) ] && echo "Linking $j --> $DEST/$(basename $j) ..."
         I_DIR=$(dirname $j)
         O_DIR=$DEST
         [ -e $O_DIR/$(basename $j) ] || ln $j $O_DIR/$(basename $j)
         if [ $? -ne 0 ] && ! [ -e $O_DIR/$(basename $j) ]; then
     	   ln -s $j $O_DIR/$(basename $j)
         fi
     done

    
    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -n $FILE_NAME -o $TORRENT $F_DIR

	for host in $TORRENT_HOSTS; do
	    [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
	done
        echo
    fi
done

for i in `find ${JENKINS_HOME}/jobs/dotOS_Builds -type f -name '*zip' | grep -i dotOS | grep -v boot`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="${F_DIR}/${FILE_NAME}.torrent"
    DEST=$TRANSMISSION_OUT/$FILE_NAME

     [ -e $DEST ] || mkdir -p $DEST

     for j in `find $F_DIR -mindepth 1 -maxdepth 1 -type f | grep -iv torrent`; do
         ! [ -f $DEST/$(basename $j) ] && echo "Linking $j --> $DEST/$(basename $j) ..."
         I_DIR=$(dirname $j)
         O_DIR=$DEST
         [ -e $O_DIR/$(basename $j) ] || ln $j $O_DIR/$(basename $j)
         if [ $? -ne 0 ] && ! [ -e $O_DIR/$(basename $j) ]; then
     	   ln -s $j $O_DIR/$(basename $j)
         fi
     done

    
    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -n $FILE_NAME -o $TORRENT $F_DIR

	for host in $TORRENT_HOSTS; do
	    [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
	done
        echo
    fi
done

for i in `find ${JENKINS_HOME}/jobs/ResurrectionRemix_Builds -type f -name '*zip' | grep rr | grep -v boot`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="${F_DIR}/${FILE_NAME}.torrent"
    DEST=$TRANSMISSION_OUT/$FILE_NAME

     [ -e $DEST ] || mkdir -p $DEST

     for j in `find $F_DIR -mindepth 1 -maxdepth 1 -type f | grep -iv torrent`; do
         ! [ -f $DEST/$(basename $j) ] && echo "Linking $j --> $DEST/$(basename $j) ..."
         I_DIR=$(dirname $j)
         O_DIR=$DEST
         [ -e $O_DIR/$(basename $j) ] || ln $j $O_DIR/$(basename $j)
         if [ $? -ne 0 ] && ! [ -e $O_DIR/$(basename $j) ]; then
     	   ln -s $j $O_DIR/$(basename $j)
         fi
     done

    
    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -n $FILE_NAME -o $TORRENT $F_DIR

	for host in $TORRENT_HOSTS; do
	    [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
	done
        echo
    fi
done

for i in `find ${JENKINS_HOME}/jobs/LineageOS_Builds -type f -name '*zip' | grep lineage | grep -v boot`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="${F_DIR}/${FILE_NAME}.torrent"
    DEST=$TRANSMISSION_OUT/$FILE_NAME
    
     [ -e $DEST ] || mkdir -p $DEST

     for j in `find $F_DIR -mindepth 1 -maxdepth 1 -type f | grep -iv torrent`; do
         ! [ -f $DEST/$(basename $j) ] && echo "Linking $j --> $DEST/$(basename $j) ..."
         I_DIR=$(dirname $j)
         O_DIR=$DEST
         [ -e $O_DIR/$(basename $j) ] || ln $j $O_DIR/$(basename $j)
         if [ $? -ne 0 ] && ! [ -e $O_DIR/$(basename $j) ]; then
     	   ln -s $j $O_DIR/$(basename $j)
         fi
     done

    
    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -n $FILE_NAME -o $TORRENT $F_DIR

	for host in $TORRENT_HOSTS; do
	    [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
	done
        echo
    fi
done

find ${JENKINS_HOME}/jobs/LineageOS_GO_Builds -type f -name '*lineage-1*' | xargs rename s'/lineage-1/lineage-go-1/'g

for i in `find ${JENKINS_HOME}/jobs/LineageOS_GO_Builds -type f -name '*zip' | grep lineage | grep -v boot`; do
    FILE_NAME=$(basename $i | sed s'/.zip//'g);
    F_DIR="$(dirname $i)"
    TORRENT="${F_DIR}/${FILE_NAME}.torrent"
    DEST=$TRANSMISSION_OUT/$FILE_NAME

     [ -e $DEST ] || mkdir -p $DEST

     for j in `find $F_DIR -mindepth 1 -maxdepth 1 -type f | grep -iv torrent`; do
         ! [ -f $DEST/$(basename $j) ] && echo "Linking $j --> $DEST/$(basename $j) ..."
         I_DIR=$(dirname $j)
         O_DIR=$DEST
         [ -e $O_DIR/$(basename $j) ] || ln $j $O_DIR/$(basename $j)
         if [ $? -ne 0 ] && ! [ -e $O_DIR/$(basename $j) ]; then
     	   ln -s $j $O_DIR/$(basename $j)
         fi
     done

    
    if ! [ -f $TORRENT ]; then
        echo "Generating torrent ${TORRENT} ..."
        mktorrent -a $TRACKERS -n $FILE_NAME -o $TORRENT $F_DIR

	for host in $TORRENT_HOSTS; do
	    [ -e $T_BIN ] && $T_BIN "$host:9091" -n "${TRANSMISSION_USERNAME}:${TRANSMISSION_PASSWORD}" -a $TORRENT
	done
        echo
    fi

done

#remove_build_lock
