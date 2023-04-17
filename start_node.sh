#!/bin/bash
if [ $# -lt 2 ]
then
	echo "Usage: ./start_node.sh nodename clustername [slurmd args]"
	exit 1
fi
set -x
nodename=$1
cluster=$2
args=$3
export SLURM_CONF="$(pwd)/${cluster}/etc/slurm.conf"
export NODE_NAME=${nodename}
sudo --preserve-env=SLURM_CONF,NODE_NAME "$(pwd)/sbin/slurmd" -N$nodename ${args}
