#!/bin/bash
# Run this from the discovery1, discovery2, or discovery3 directories to
# setup the environment.
SYSCONF=`pwd`
export PATH=$SYSCONF/bin:$SYSCONF/sbin:$PATH
export MANPATH=$SYSCONF/share/man:$MANPATH
source ../slurm/contribs/slurm_completion_help/slurm_completion.sh
export SLURM_CONF=$SYSCONF/etc/slurm.conf
