#!/bin/bash
# start_clusters.sh
# Startup script for Slurm
# Usage:
#  ./start_clusters.sh [<number_of_clusters>]
# number_of_clusters is optional. If not given, then 1 cluster will start.
# Restrict number_of_clusters to between 1 and 3, since 1 is the minimum
# and 3 is how many clusters I have configured, so 3 is the maximum.
num_clusters=1
slurmctld_flags=''
verbose=0

print_usage() {
	printf "Usage: ./start_clusters.sh [-c<num_clusters>]\n"
}

validate_number() {
	num=$1
	min=$2
	max=$3
	arg_str=$4
	is_not_num_regex='[^0-9]+'

	if [[ $num =~ $is_not_num_regex || $num -gt $max || $num_clusters -lt $min ]]
	then
		echo "Error: Invalid argument $arg_str=$num: it must be between $min and $max, inclusivce."
		exit 1
	fi
}

while getopts 'c:o:uv' flag
do
	case "${flag}" in
		c) num_clusters=${OPTARG} ;;
		o) slurmctld_flags=${OPTARG} ;;
		u) print_usage
		   exit 1 ;;
		v) verbose=1 ;;
	esac
done

if [ $verbose -ne 0 ]
then
	echo "num_clusters=$num_clusters"
	echo "slurmctld_flags=$slurmctld_flags"
fi

# Validate num_clusters
validate_number $num_clusters 1 3 "-c"

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
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
	sudo -u #USER $installpath/sbin/slurmctld -f $SLURM_CONF $slurmctld_flags
	i=$(($i+1))
done

# Start slurmd's - start them all in parallel
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
		sudo $installpath/sbin/slurmd -f $SLURM_CONF -N n$cluster_inx-$node_inx &
		node_inx=$(($node_inx+1))
	done
	cluster_inx=$(($cluster_inx+1))
done
wait
