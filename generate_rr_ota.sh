#!/bin/bash

if [ "x$1" == "x" ]; then
	echo "USAGE: ${0} filename_1 filename_2 ..."
	exit
fi

spacer='  '
#spacer='\t'

echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<SlimOTA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="ota.xsd">'
echo -e "${spacer}<Stable>"


while [ -n "$1" ]; do
	base_url="https://github.com/Galaxy-MSM8916/releases/releases/download/$1"
	#rr-oreo-j38-20190107-NIGHTLY-gprimelte
	codename=`echo $1|cut -d'-' -f6`
	echo -e "${spacer}${spacer}<${codename}>"

	echo -e "${spacer}${spacer}${spacer}<Filename>${1}</Filename>"
	echo -e "${spacer}${spacer}${spacer}<RomUrl"
	echo -e "${spacer}${spacer}${spacer}${spacer}id=\"rom\""
	echo -e "${spacer}${spacer}${spacer}${spacer}title=\"Rom\""
	echo -e "${spacer}${spacer}${spacer}${spacer}description=\"Download RR builds\">${base_url}/${1}.zip</RomUrl>"

	echo -e "${spacer}${spacer}${spacer}<ChangelogUrl"
	echo -e "${spacer}${spacer}${spacer}${spacer}id=\"changelog\""
	echo -e "${spacer}${spacer}${spacer}${spacer}title=\"Changelog\""
	echo -e "${spacer}${spacer}${spacer}${spacer}description=\"View Changelog\">${base_url}/changelog-${1}.txt</ChangelogUrl>"

	echo -e "${spacer}${spacer}</${codename}>"
	shift
done

echo -e "${spacer}</Stable>"
echo '</SlimOTA>'
