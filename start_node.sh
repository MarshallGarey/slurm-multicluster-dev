#!/bin/bash
if [ $# -lt 2 ]
then
	echo "Usage: ./start_node.sh nodename clustername [slurmd args]"
	exit 1
fi
set -x
nodename=$1
cluster=$2
shift
shift
# Get path to script: https://stackoverflow.com/a/1482133/4880288
install_path="$(dirname -- "$( readlink -f -- "$0"; )";)"
export SLURM_CONF="${install_path}/${cluster}/etc/slurm.conf"
export NODE_NAME=${nodename}
sudo --preserve-env=SLURM_CONF,NODE_NAME "$(pwd)/sbin/slurmd" -N$nodename "${@}"
