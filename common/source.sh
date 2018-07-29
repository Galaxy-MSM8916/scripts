#!/bin/bash

script_dir=`realpath $(dirname $0)`

function source_build() {
# source common functions
    for file in `find $script_dir/build_script -name '*sh'`; do
        . $file
    done
}

function source_common() {
# source common functions
    for file in `find $script_dir/common -name '*sh'`; do
        . $file
    done
}
