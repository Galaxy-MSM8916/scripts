#!/bin/bash

function acquire_build_lock {

    local lock_name="android_build_lock"
    local lock="/var/lock/${lock_name}"

    exec 200>${lock}

    echoTextBlue "Attempting to acquire lock $lock..."

    # loop if we can't get the lock
    while true; do
        flock -n 200
        if [ $? -eq 0 ]; then
            break
        else
            printf "%c" "."
            sleep 5
        fi
    done

    # set the pid
    pid=$$
    echo ${pid} 1>&200

    echoTextBlue "Lock ${lock} acquired. PID is ${pid}"
}

function remove_build_lock {
    echoText "Removing lock..."
    exec 200>&-
}
