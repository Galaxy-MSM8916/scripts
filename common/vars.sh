#!/bin/bash

# set home
[ -z "$JENKINS_HOME" ] && export JENKINS_HOME=$HOME

# transmission
TRANSMISSION_USERNAME="transmission"
[ -z "$TRANSMISSION_PASSWORD" ] && TRANSMISSION_PASSWORD="transmission"
