#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
#This line is importat, otherwise pip installs with errors
export LC_ALL=C

echo "Updating and upgrading apt-get" > aptgetoutput.log
apt-get --yes update >> aptgetoutput.log && apt-get --yes upgrade >> aptgetoutput.log
apt-get --yes install libreoffice --no-install-recommends >> aptgetoutput.log
apt-get --yes install openjdk-8-jre-headless >> aptgetoutput.log
apt-get --yes install libreoffice-java-common >> aptgetoutput.log
apt-get --yes install python-minimal >> aptgetoutput.log

