#!/bin/bash

############
#          #
#  COLORS  #
#          #
############
BLUE='\033[1;35m'
BOLD="\033[1m"
GREEN="\033[01;32m"
NC='\033[0m' # No Color
RED="\033[01;31m"
RESTORE=$NC

function logr {
    echo -e ${RED} "$@" ${NC}
}

function logb {
    echo -e ${BLUE} "$@" ${NC}
}

function logg {
    echo -e ${GREEN} "$@" ${NC}
}

function log {
    echo -e "$@"
}

# PRINTS A FORMATTED HEADER TO POINT OUT WHAT IS BEING DONE TO THE USER
function echoText() {
    echoTextRed "$@"
}

function echoTextRed() {
    echo -e ${RED}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextBlue() {
    echo -e ${BLUE}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextGreen() {
    echo -e ${GREEN}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

function echoTextBold() {
    echo -e ${BOLD}
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e "==  ${@}  =="
    echo -e "====$( for i in $( seq 1 `echo $@ | wc -c | sed s/[0-9]../100/g` ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

# CREATES A NEW LINE IN TERMINAL
function newLine() {
    echo -e ""
}

# PRINTS AN ERROR IN BOLD RED
function reportError() {
    RED="\033[01;31m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${RED}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}
