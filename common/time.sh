#!/bin/bash

START_TIME=$( date +%s )

# FORMATS THE TIME
function format_time() {
    MINS=$(((${1}-${2})/60))
    SECS=$(((${1}-${2})%60))
    if [[ ${MINS} -ge 60 ]]; then
        HOURS=$((${MINS}/60))
        MINS=$((${MINS}%60))
    fi

    if [[ ${HOURS} -eq 1 ]]; then
        TIME_STRING+="1 hour, "
    elif [[ ${HOURS} -ge 2 ]]; then
        TIME_STRING+="${HOURS} hours, "
    fi

    if [[ ${MINS} -eq 1 ]]; then
        TIME_STRING+="1 minute"
    else
        TIME_STRING+="${MINS} minutes"
    fi

    if [[ ${SECS} -eq 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", and 1 second"
    elif [[ ${SECS} -eq 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" and 1 second"
    elif [[ ${SECS} -ne 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", and ${SECS} seconds"
    elif [[ ${SECS} -ne 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" and ${SECS} seconds"
    fi

    echo ${TIME_STRING}
}
