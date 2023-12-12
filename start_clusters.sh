#!/bin/bash
# start_clusters.sh
# Startup script for Slurm
# Print usage with ./start_clusters -h
num_clusters=1
num_nodes=10
slurmctld_flags=''
verbose=0

print_usage() {
	printf "\
Usage: ./start_clusters.sh [-c<num_clusters>] [-h] [-n<num_nodes>] \
[-o<'slurmctld_flags'>] [-v]

-c: Number of clusters to start. Valid numbers: 1, 2, or 3.
-f: Path to alternate slurm.conf.
-h: Print this usage string.
-n: Number of nodes (slurmd's) to start. Valid numbers: 1-99.
-o: Flags to pass to slurmctld. Must be surrounded by quotes.
-v: Print verbose logs.
"
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

while getopts 'c:f:hn:o:uv' flag
do
	case "${flag}" in
		c) num_clusters=${OPTARG} ;;
		f) slurm_conf=${OPTARG} ;;
		h) print_usage
		   exit 1 ;;
		n) num_nodes=${OPTARG} ;;
		o) slurmctld_flags=${OPTARG} ;;
		v) verbose=1 ;;
	esac
done

if [ $verbose -ne 0 ]
then
	echo "num_clusters=$num_clusters"
	echo "num_nodes=$num_nodes"
	echo "slurmctld_flags=$slurmctld_flags"
	set -x
fi

# Validate options
validate_number $num_clusters 1 3 "-c"
validate_number $num_nodes 1 99 "-n"

installpath="#INSTALL_PATH"

if [ $num_clusters -eq 1 ]
then
	echo "Starting cluster c1"
else
	echo "Starting clusters c[1-$num_clusters]"
fi

sudo ./stop_clusters.sh

# Start slurmdbd
$installpath/sbin/slurmdbd
sleep 1

# Start slurmctld's
i=1
while [ $i -le $num_clusters ]
do
	if [ -z "${slurm_conf}" ]
	then
		SLURM_CONF="$installpath/c$i/etc/slurm.conf"
	else
		SLURM_CONF="${slurm_conf}"
	fi
	$installpath/sbin/slurmctld -f $SLURM_CONF $slurmctld_flags
	i=$(($i+1))
done

# Start slurmd's - start them all in parallel
i=1
while [ $i -le $num_clusters ]
do
	node_inx=1
	if [ -z "${slurm_conf}" ]
	then
		SLURM_CONF="$installpath/c$i/etc/slurm.conf"
	else
		SLURM_CONF="${slurm_conf}"
	fi
	while [ $node_inx -le $num_nodes ]
	do
		nodename="n${i}-${node_inx}"
		echo "Start node ${nodename}"
		export NODE_NAME=${nodename}
		sudo --background --preserve-env=NODE_NAME $installpath/sbin/slurmd -f $SLURM_CONF -N ${nodename}

		node_inx=$(($node_inx+1))
	done
	i=$(($i+1))
done

if [ $verbose -ne 0 ]
then
	set +x
fi
