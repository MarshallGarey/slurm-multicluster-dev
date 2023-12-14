#!/bin/bash
if [ $# -ne 2 ]
then
	echo "Usage: sudo ./stop_node.sh nodename clustername"
	exit 1
fi
set -x
nodename=$1
cluster=$2

# Get path to script: https://stackoverflow.com/a/1482133/4880288
install_path="$(dirname -- "$( readlink -f -- "$0"; )";)"

sudo kill $(cat "${install_path}/${cluster}/run/slurmd-${nodename}.pid")
