#!/bin/sh

export EXPANDROOT=true
export TIMEZONE="Europe/Prague"
export ENABLE_CONSOLE=false
export ENABLE_SOUND=false
export ENABLE_MINGPU=false
export ENABLE_RSYSLOG=false
export ENABLE_USER=false
export ENABLE_ROOT=true
export ENABLE_ROOT_SSH=true

./rpi2-gen-image.sh
