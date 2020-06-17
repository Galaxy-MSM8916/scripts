#!/bin/sh
PDIR=`pwd`
ZONEDIR="/etc/bind" #location of your zone files
KEYDIR="/etc/bind/keys" #location of your zone files
ZONE=$1
ZONEFILE=$2
DNSSERVICE="bind9" #On CentOS/Fedora replace this with "named"
cd $ZONEDIR
#SERIAL=`/usr/sbin/named-checkzone $ZONE $ZONEFILE | egrep -ho '[0-9]{10}'`
#sed -i 's/'$SERIAL'/'$(($SERIAL+1))'/' $ZONEFILE
SERIAL=`/usr/sbin/named-checkzone $ZONE $ZONEFILE | grep -P -ho ': loaded serial\s+\K[0-9]+$'`
sed -i 's/'$SERIAL'\(\s*\); Serial/'$(($SERIAL+1))'\1; Serial/' $ZONEFILE
/usr/sbin/dnssec-signzone -K $KEYDIR -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N increment -o $1 -t $2
systemctl reload $DNSSERVICE
cd $PDIR
