#!/bin/bash
if [ $# -ne 2 ]
then
	echo "Usage: sudo ./stop_node.sh nodename clustername"
	exit 1
fi
set -x
nodename=$1
cluster=$2
installpath="#INSTALL_PATH"
sudo kill $(cat "${installpath}/${cluster}/run/slurmd-${nodename}.pid")
