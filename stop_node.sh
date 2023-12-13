#!/bin/bash
if [ $# -ne 2 ]
then
	echo "Usage: sudo ./stop_node.sh nodename clustername"
	exit 1
fi
set -x
nodename=$1
cluster=$2

if [ -z "${INSTALL_PATH}" ]
then
	echo "INSTALL_PATH is not set in the environment; assuming $(pwd)"
	export INSTALL_PATH="$(pwd)"
fi
install_path="${INSTALL_PATH}"

sudo kill $(cat "${install_path}/${cluster}/run/slurmd-${nodename}.pid")
