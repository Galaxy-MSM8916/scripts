#!/bin/bash

if [ -n "$1" ]; then
	DIR=$1
else
	DIR=/var/lib/jenkins/jobs/
fi

to_delete="
http://tracker.msm8916.com:6969/announce
udp://tracker.msm8916.com:6969/announce
udp://tracker-1.msm8916.com:6969/announce
udp://tracker-2.msm8916.com:6969/announce
udp://tracker.leechers-paradise.org:6969
udp://tracker.coppersurfer.tk:6969
"

to_add="
http://tracker-1.msm8916.com:6969/announce
http://tracker-2.msm8916.com:6969/announce
"

for torrent in `find $DIR -type f -name '*.torrent'`; do
	for tracker in $to_delete; do
		transmission-edit -d $tracker $torrent
	done

	for tracker in $to_add; do
		transmission-edit -a $tracker $torrent
	done
done	
