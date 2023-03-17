#!/bin/bash
# start_slurmds.sh
# Startup script for slurmds
node_name='n'
num_clusters=1
num_nodes=10
slurmd_flags=''
verbose=0

print_usage() {
	printf "\
Usage: ./start_slurmds.sh [-c<num_clusters>] [-h] [-n<num_nodes>] \
[-o<'slurmd_flags'>] [-v]

-h: Print this usage string.
-n: Number of nodes (slurmd's) to start. Valid numbers: 1-99.
-N: NodeName (if not given, NodeName is 'n')
-o: Flags to pass to slurmd. Must be surrounded by quotes.
-v: Print verbose logs.
"
}

validate_number() {
	num=$1
	min=$2
	max=$3
	arg_str=$4
	is_not_num_regex='[^0-9]+'

	if [[ $num =~ $is_not_num_regex || $num -gt $max || $num -lt $min ]]
	then
		echo "Error: Invalid argument $arg_str=$num: it must be between $min and $max, inclusivce."
		exit 1
	fi
}

while getopts 'c:hn:N:o:uv' flag
do
	case "${flag}" in
		c) num_clusters=${OPTARG} ;;
		h) print_usage
		   exit 1 ;;
		n) num_nodes=${OPTARG} ;;
		N) node_name=${OPTARG} ;;
		o) slurmd_flags=${OPTARG} ;;
		v) verbose=1 ;;
	esac
done

if [ $verbose -ne 0 ]
then
	echo "num_clusters=$num_clusters"
	echo "node_name=$node_name"
	echo "num_nodes=$num_nodes"
	echo "slurmd_flags=$slurmd_flags"
fi

# Validate options
validate_number $num_clusters 1 3 "-c"
validate_number $num_nodes 1 99 "-n"

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

installpath="#INSTALL_PATH"

if [ $num_clusters -eq 1 ]
then
	echo "Starting $num_nodes slurmds NodeName=$node_name in cluster c1"
else
	echo "Starting $num_nodes slurmds NodeName=$node_name in clusters c[1-$num_clusters]"
fi

# Start slurmd's
cluster_inx=1
while [ $cluster_inx -le $num_clusters ]
do
	node_inx=1
	SLURM_CONF="$installpath/c$cluster_inx/etc/slurm.conf"
	while [ $node_inx -le $num_nodes ]
	do
		full_name="$node_name$cluster_inx-$node_inx"
		#echo "Start node $full_name"
		echo "sudo $installpath/sbin/slurmd -f $SLURM_CONF -N $full_name $slurmd_flags"
		# Start in parallel by backgrounding the slurmd
		#sudo $installpath/sbin/slurmd -f $SLURM_CONF -N $full_name $slurmd_flags &
		# Start sequentially
		export NODE_NAME=$full_name
		sudo --preserve-env=NODE_NAME $installpath/sbin/slurmd -f $SLURM_CONF -N $full_name $slurmd_flags
		node_inx=$(($node_inx+1))
		# Delay for testing
		#sleep 0.5
	done
	cluster_inx=$(($cluster_inx+1))
done
