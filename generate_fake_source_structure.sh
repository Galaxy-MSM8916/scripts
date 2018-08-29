#!/bin/bash

# TODO: add usage, allow specifying repo dir and target fake source dir

target_dir=lineage

for i in `ls|grep android_`; do
    dir=`echo $i|sed s/android_//g|sed s/\.git//g | sed s'/_/\//'g`;
    mkdir -p $target_dir/$dir; ln -s $PWD/$i/.git $target_dir/$dir/;
    git -C $target_dir/$dir reset --hard;
done

for i in `ls|grep proprietary_`; do
    dir=`echo $i|sed s/proprietary_//g|sed s/\.git//g | sed s'/_/\//'g`;
    mkdir -p $target_dir/$dir; ln -s $PWD/$i/.git $target_dir/$dir/;
    git -C $target_dir/$dir reset --hard;
done

git clone https://github.com/LineageOS/android_vendor_lineage.git lineage/vendor/lineage --depth=1
