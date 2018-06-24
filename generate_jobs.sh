#!/bin/bash

# source 'script' functions
. $(dirname $0)/common/source.sh
# source common scripts
source_common

# update the repo
update_repo

NEWLINE="
"

HOST_USER=jenkins
HOST_NAME=jenkins.msm8916.com

function generate_folder_config() {
# generate_folder_config FOLDER_NAME CONFIG_PATH
local FOLDER_NAME=`remove_underscores $1`
local CONFIG_PATH=$2

if ! [ -f $CONFIG_PATH ]; then
mkdir -p $(dirname $CONFIG_PATH)
cat <<CONFIG_FILE_F > ${CONFIG_PATH}
<?xml version='1.0' encoding='UTF-8'?>
<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.0.4">
  <actions/>
  <description></description>
  <displayName>$FOLDER_NAME</displayName>
  <properties>
    <com.cloudbees.hudson.plugins.folder.properties.FolderCredentialsProvider_-FolderCredentialsProperty>
      <domainCredentialsMap class="hudson.util.CopyOnWriteMap\$Hash">
        <entry>
          <com.cloudbees.plugins.credentials.domains.Domain plugin="credentials@2.1.13">
            <specifications/>
          </com.cloudbees.plugins.credentials.domains.Domain>
          <java.util.concurrent.CopyOnWriteArrayList>
            <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.1.13">
              <id>fc700093-f1c0-4a9f-9fe4-05ffbf031a04</id>
              <description></description>
              <password>{AQAAABAAAAEwTMI9ZHoBapZN8l7SW6evceOEy31UC5u88XLukcQDpGpw1eMBUBzIrWsz9fJaGIGyDo2mVJ78LydXkI9ol2hUWO7uS1bWV7LMK+Zg+k4E6FljJQ1ehKJ+igbJ0BnKcIIXMJ66YwjI/YPiwgAoIiT0P0A/J8RKEM5lrIH/bbIQVMf0VLtkLmRU7c5SLPgSCBM+lcTt+AV36ma9RPs3NMCMhxQu/PhUkgfDt3TR7sbsB96b4j3493qnPTxlhyqO967VajslELFUBVTrnDaXHJomQ++iyYGxQYGHx2fRn3H2hNDBjJQpybRScIisVg7KZ3f9okjnibNIgieC6RzA6Vo5Q25K9eZEOTkdP4pRynnB0skkwDhcYMAQ3Qv2dYrv7UASbgtlSJSoNbzHB/dEvi/kQk1fXAcz5+O8ip152tvIobk=}</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
            <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.1.13">
              <id>86eb4de2-2fe4-414d-9b01-4c06bc24fc1e</id>
              <description></description>
              <password>{AQAAABAAAAEwaNWmwgx5aqY+gvly4TKICpz9nMqSX0CbXkoqeSJFdnT79NBCjhvqHdR0gniSHHlSQ79zESSCloOB8/4uMaRQHnZX3Qtdz0B/W1wKrw2uuVhKL492vHScNTGVahKTYIqlOptMmHbReBeHKYh70hdm57FRi5u0tDCaX/VKGVk6pZzSKoCDsYpY1gYbqGcUPP6teiZm6elyFbLu2nFzz+Dtnk764yOheT7FYLgNBQA9Ll1LBpZBKWI6dVx7Po8kFLfd5d78xkdW9zSohQqn/CvfOt9ZwJ04nxTzZweMFzx3HxQMEa51TQN6yLV7a/c6JSa0rDi0w9Rey60fgx9i+b6ejiwq0bE9aQKCfn3eDLjM3rbRnfrfM8HymRVIyZZO1r2h7h9FfsnkY0O7JBrY4TwaaJOhMFWGQwko51+dGcSPB8I=}</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
          </java.util.concurrent.CopyOnWriteArrayList>
        </entry>
      </domainCredentialsMap>
    </com.cloudbees.hudson.plugins.folder.properties.FolderCredentialsProvider_-FolderCredentialsProperty>
  </properties>
  <folderViews class="com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder">
    <views>
      <hudson.model.AllView>
        <owner class="com.cloudbees.hudson.plugins.folder.Folder" reference="../../../.."/>
        <name>all</name>
        <description></description>
        <filterExecutors>false</filterExecutors>
        <filterQueue>false</filterQueue>
        <properties class="hudson.model.View\$PropertyList"/>
      </hudson.model.AllView>
    </views>
    <primaryView>all</primaryView>
    <tabBar class="hudson.views.DefaultViewsTabBar"/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/>
</com.cloudbees.hudson.plugins.folder.Folder>
CONFIG_FILE_F
fi
}

function generate_job_config() {
# generate_job_config CONFIG_PATH
local CONFIG_PATH=$1

if [ "x$CONFIG_PATH" != "x" ]; then
  mkdir -p $(dirname $CONFIG_PATH)

  display_extra=
  if [ "x$JOB_DESCRIPTION" != "x" ]; then
    display_extra="(${JOB_DESCRIPTION}) "
  fi
 
  if [ "x$DEVICE_EXTRA_DESC" != "x" ]; then
    display_extra+="(${DEVICE_EXTRA_DESC}) "
  fi

  args_extra=
  gen_torrents=

  if [ "$BUILD_TARGET" == "otapackage" ] || [ "$BUILD_TARGET" == "bootimage" ] || [ "$BUILD_TARGET" == "recoveryimage" ]; then
    args_extra="   <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>EXTRA_ARGS</name>
          <description>Extra arguments to pass to the build script.</description>
          <defaultValue></defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>"
    gen_torrents="    <hudson.tasks.Shell>
      <command>ssh jenkins@msm8916.com &quot;~/bin/add_create_torrents.sh&quot;</command>
    </hudson.tasks.Shell>"
  elif [ "$BUILD_TARGET" == "promote" ]; then
    args_extra="   <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>JOB_NUM</name>
          <description>Job number to promote.</description>
          <defaultValue></defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>GO</name>
          <description>Promote GO build. Set 1 to promote GO, 0 otherwise.</description>
          <defaultValue>0</defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>"
  elif [ "$BUILD_TARGET" == "demote" ]; then
    args_extra="   <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>GO</name>
          <description>Demote GO build. Set 1 to demote GO, 0 otherwise.</description>
          <defaultValue>0</defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>"
  fi

  if [ -n "$ASSIGNED_NODE" ]; then
  FIX_NODE="<assignedNode>${ASSIGNED_NODE}</assignedNode>"
  fi

  cat <<CONFIG_FILE_F > ${CONFIG_PATH}
<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description>${JOB_EXTENDED_DESCRIPTION}</description>
  <displayName>${DIST_LONG} ${DIST_VERSION}: ${DEVICE_CODENAME} [ ${DEVICE_MODEL} $display_extra]</displayName>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.plugins.buildblocker.BuildBlockerProperty plugin="build-blocker-plugin@1.7.3">
      <useBuildBlocker>true</useBuildBlocker>
      <blockLevel>GLOBAL</blockLevel>
      <scanQueueFor>DISABLED</scanQueueFor>
      <blockingJobs>${BLOCKING_JOBS}</blockingJobs>
    </hudson.plugins.buildblocker.BuildBlockerProperty>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>-1</daysToKeep>
        <numToKeep>${BUILDS_TO_KEEP}</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>${BUILDS_TO_KEEP}</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
${args_extra}
  </properties>
  <scm class="hudson.scm.NullSCM"/>
  ${FIX_NODE}
  <canRoam>${CAN_ROAM}</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <authToken>${BUILD_TRIGGER_TOKEN}</authToken>
  <triggers/>
  <concurrentBuild>true</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>${SHELL_COMMANDS}</command>
    </hudson.tasks.Shell>
${gen_torrents}
  </builders>
  <buildWrappers>
    <hudson.plugins.timestamper.TimestamperBuildWrapper plugin="timestamper@1.8.8"/>
    <hudson.plugins.ansicolor.AnsiColorBuildWrapper plugin="ansicolor@0.5.0">
      <colorMapName>xterm</colorMapName>
    </hudson.plugins.ansicolor.AnsiColorBuildWrapper>
    <org.jenkinsci.plugins.builduser.BuildUser plugin="build-user-vars-plugin@1.5"/>
  </buildWrappers>
</project>
CONFIG_FILE_F
fi
}

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -i | --input Path to job description file or directory"
    echo "               containing decription files."

    echo "  -d | --path  Path to Jenkins' job directory"
    echo "  -h | --help  Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -i | --input)           shift
                                JOB_FILE_INPUT=$1
                                ;;
        -d | --path )           shift
                                JENKINS_JOB_DIR=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

if [ "x$JENKINS_JOB_DIR" == "x" ]; then
    JENKINS_JOB_DIR="/var/lib/jenkins/jobs"
fi

# clean up the dirs
for jobs_folder in $(find $JENKINS_JOB_DIR  -name jobs 2>/dev/null| tac); do
    for job_dir in $(find $jobs_folder -maxdepth 1 -type d 2>/dev/null); do
        file_count=$(find $job_dir -type f 2>/dev/null | wc -l)
        if [ $file_count -le 3 ]; then
            rm -rf $job_dir
        fi
    done
done

rmdir $(find $JENKINS_JOB_DIR -type d -empty 2>/dev/null) 2>/dev/null

# find the job description files
if [ -f ${JOB_FILE_INPUT} ]; then
    JOB_DESC_FILES=${JOB_FILE_INPUT}
elif [ -d ${JOB_FILE_INPUT} ]; then
    JOB_DESC_FILES=$(find ${JOB_FILE_INPUT} -type f)
else
    echo "Invalid --input argument specified"
    exit 1
fi

function substitute_string {
# substitute_string $string
    new_string=`echo "$@" | sed s'/##/$/'g`
    eval "echo $new_string"
}

function split_variable {
# split_variable $variable
    echo $1 | sed s"/$SEPARATOR/ /"g
}

function extract_field {
# extract_field string $field_num $separator
    if [ "x$3" == "x" ]; then
        separator=':'
    else
        separator=$3
    fi
    echo $1 | cut -d "$separator" -f $2
}

function remove_underscores {
    result=$(echo $@ | sed s'/__/ /'g)
    result=$(echo $result | sed s'/_/ /'g)
    echo $result
}

for file in $JOB_DESC_FILES; do

    # clear some variables
    BUILDS_TO_KEEP=4
    DEVICES=
    JOB_DESCRIPTION=
    JOB_DIR_PROPER=
    SHELL_COMMANDS_EXTRA=

    # source the job description files
    . $file

    # generate the job dirs
    while [ $(dirname $JOB_DIR) != "." ]; do
        JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"
        JOB_DIR=$(dirname $JOB_DIR)
    done
    JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"

    # generate the job configs
    JOB_DIR=$JOB_DIR_PROPER
    while [ $(dirname $JOB_DIR) != "." ]; do
        JOB_DIR_NAME=$(basename $JOB_DIR)
        if [ $JOB_DIR_NAME == "jobs" ]; then
            JOB_DIR_NAME=$(dirname $JOB_DIR)
            [ $(basename $JOB_DIR_NAME) != "." ] && JOB_DIR_NAME=$(basename $JOB_DIR_NAME)

            generate_folder_config $JOB_DIR_NAME ${JENKINS_JOB_DIR}/$(dirname $JOB_DIR)/config.xml
        fi
        JOB_DIR=$(dirname $JOB_DIR)
    done

    # save these variables for later use
    JOB_EXTENDED_DESCRIPTION_OLD=$JOB_EXTENDED_DESCRIPTION
    BUILD_DIR_OLD=$BUILD_DIR

    SSH="ssh -o StrictHostKeyChecking=no"

    for DIST_VERSION in `split_variable $DIST_VERSION`; do
        for DEVICE_LINE in `split_variable $DEVICES`; do

            DEVICE_CODENAME=`extract_field $DEVICE_LINE 1`
            DEVICE_MODEL=`extract_field $DEVICE_LINE 2`
            DEVICE_EXTRA_DESC=`extract_field $DEVICE_LINE 3`
            DEVICE_EXTRA_DESC=`remove_underscores $DEVICE_EXTRA_DESC`

            JOB_EXTENDED_DESCRIPTION=`substitute_string $JOB_EXTENDED_DESCRIPTION_OLD`
            BUILD_DIR=`substitute_string $BUILD_DIR_OLD`

            SHELL_COMMANDS_EXTRA=`substitute_string ${SHELL_COMMANDS_EXTRA}`

            JOB_BASE_NAME=${JOB_PREFIX}-${DIST_VERSION}-${DEVICE_CODENAME}
            JOB_DIR_PATH=${JENKINS_JOB_DIR}/${JOB_DIR_PROPER}/${JOB_BASE_NAME}/
            CONFIG_PATH=${JOB_DIR_PATH}/config.xml

            mkdir -p $JOB_DIR_PATH

            if [ "$DIST_VERSION" == "14.1" ]; then
                OTA_VER=14
            elif [ "$DIST_VERSION" == "15.1" ]; then
                OTA_VER=15
            fi

            if [ "$BUILD_TARGET" == "otapackage" ] || [ "$BUILD_TARGET" == "bootimage" ] || [ "$BUILD_TARGET" == "recoveryimage" ]; then

                CAN_ROAM=true

                SHELL_COMMANDS="JOB_URL=https://${HOST_NAME}/job/$(echo ${JOB_DIR_PROPER} | sed s/jobs/job/g)\${JOB_BASE_NAME}/\${BUILD_NUMBER}"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="JOB_DESCRIPTION=\"$JOB_EXTENDED_DESCRIPTION\""
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="\${BUILD_BIN_ROOT}/build.sh --path \${BUILD_ANDROID_ROOT}/${BUILD_DIR} --distro ${DIST} \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="--device ${DEVICE_CODENAME} --target ${BUILD_TARGET} -j \${MAX_JOB_NUMBER} \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="--output \${JENKINS_HOME}/jobs/${JOB_DIR_PROPER}\${JOB_BASE_NAME}/builds/\${BUILD_NUMBER}/archive/ \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="-b \${BUILD_NUMBER} --type=${BUILD_TYPE} -v \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="--job-url \"\${JOB_URL}\" \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="--description \"\${JOB_DESCRIPTION}\" \\"
                SHELL_COMMANDS+=${NEWLINE}
                SHELL_COMMANDS+="--host ${HOST_USER}@${HOST_NAME} ${SHELL_COMMANDS_EXTRA} \$EXTRA_ARGS"

            elif [ "$BUILD_TARGET" == "promote" ]; then
                CAN_ROAM=false

                SHELL_COMMANDS="~/bin/ota.sh -t ${BUILD_TARGET} -d ${DEVICE_CODENAME} -v ${OTA_VER} -j \$JOB_NUM"
                SHELL_COMMANDS+=${NEWLINE}
            elif [ "$BUILD_TARGET" == "demote" ]; then

                CAN_ROAM=false

                SHELL_COMMANDS="~/bin/ota.sh -t ${BUILD_TARGET} -d ${DEVICE_CODENAME} -v ${OTA_VER}"
                SHELL_COMMANDS+=${NEWLINE}
            fi

            echo "Generating job \"$JOB_EXTENDED_DESCRIPTION\"..."
            generate_job_config $CONFIG_PATH
        done
        echo
    done
done
