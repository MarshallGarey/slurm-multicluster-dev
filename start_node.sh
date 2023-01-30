#!/bin/bash
set -x
nodename=$1
cluster=$2
args=$3
export SLURM_CONF="$(pwd)/${cluster}/slurm.conf"
export NODE_NAME=${nodename}
sbin/slurmd -N$nodename ${args}
