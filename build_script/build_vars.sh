#!/bin/bash

# locale
export LC_ALL=C

# telegram
BUILD_TELEGRAM_CHATID="@Samsung_MSM89XX"
BUILD_TELEGRAM_TOKEN=""

# ccache
export CCACHE_COMPRESS="1"
[ -z "$CCACHE_DIR" ] && export CCACHE_DIR="${JENKINS_HOME}/ccache"
[ -z "$CCACHE_MAXSIZE" ] && export CCACHE_MAXSIZE="60G"
export USE_CCACHE="1"

[ -z "$MAX_JOB_NUMBER" ] && MAX_JOB_NUMBER="15"
