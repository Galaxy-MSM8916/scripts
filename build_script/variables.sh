#!/bin/bash

# file transfer retry count
UPLOAD_RETRY_COUNT=3

# create a temprary working dir
BUILD_TEMP=$(mktemp -d)

ARTIFACT_OUT_DIR=${BUILD_TEMP}/builds

SAVED_BUILD_JOBS_DIR=/tmp/android_build_jobs

#changelog
CHANGELOG_DAYS=5

CURL="curl --silent -connect-timeout=10"

# file extraction function names
COPY_FUNCTIONS=();
POST_COPY_FUNCTIONS=();

REPO_REF_MAP=();

SILENT=0

LOCAL_REPO_PICKS=
LINEAGE_REPO_PICKS=

LOCAL_REPO_TOPICS=
LINEAGE_REPO_TOPICS=

# declare globals for argv helper
# declare some globals
release_type=""
ver=""
distroTxt=""
recovery_variant=""
recovery_flavour=""

arc_name=""
rec_name=""
bimg_name=""
boot_tar_name=""

chipset=`find_chipset $DEVICE_NAME`
vendor="samsung"

DISTROS="
omni
lineage
lineage-go
cm
rr
AOSPA
dotOS"

BUILD_START_TIME=
