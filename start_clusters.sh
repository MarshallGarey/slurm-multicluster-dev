#!/bin/bash
# start_clusters.sh
# Startup script for Slurm
# Usage:
#  ./start_clusters.sh [<number_of_clusters>]
# number_of_clusters is optional. If not given, then 1 cluster will start.
# Restrict number_of_clusters to between 1 and 3, since 1 is the minimum
# and 3 is how many clusters I have configured, so 3 is the maximum.

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

# $# is the number of arguments passed to the script
if [ $# -ne 0 ]
then
	is_not_num_regex='[^0-9]+'
	if [[ $1 =~ $is_not_num_regex || $1 -ge 4 || $1 -le 0 ]]
	then
		echo "Error: Invalid argument ($1) - it must be 1, 2, or 3"
		exit 1
	fi
	num_clusters=$1
else
	num_clusters=1
fi

installpath="/home/#USER/slurm/#VERSION/install"

if [ $num_clusters -eq 1 ]
then
	echo "Starting cluster c1"
else
	echo "Starting clusters c[1-$num_clusters]"
fi

# Start slurmdbd
sudo -u #USER $installpath/sbin/slurmdbd
sleep 1

# Start slurmctld's
i=1
while [ $i -le $num_clusters ]
do
	SLURM_CONF="$installpath/c$i/etc/slurm.conf"
	sudo -u #USER SLURM_CONF=$SLURM_CONF $installpath/sbin/slurmctld -i -f $SLURM_CONF
	i=$(($i+1))
done

# Start slurmd's
num_nodes=10
cluster_inx=1
while [ $cluster_inx -le $num_clusters ]
do
	node_inx=1
	#SLURM_CONF="$installpath/c$cluster_inx/etc/slurm.conf"
	SLURM_CONF="$installpath/c$cluster_inx/etc/slurm.conf"
	while [ $node_inx -le $num_nodes ]
	do
		echo "Start node n$cluster_inx-$node_inx"
		sudo $installpath/sbin/slurmd -f $SLURM_CONF -N n$cluster_inx-$node_inx
		node_inx=$(($node_inx+1))
	done
	cluster_inx=$(($cluster_inx+1))
done
