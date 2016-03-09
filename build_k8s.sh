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
export CMDLINE="cgroup_enable=memory swapaccount=1"

export VROUTER_ADDRESS="172.16.1.141"
export K8S_API_SERVER="https://10.0.175.17:443"
export K8S_CLUSTER_DNS="10.254.0.10"
export K8S_CLUSTER_DOMAIN="cluster.local"

./rpi2-gen-image.sh
