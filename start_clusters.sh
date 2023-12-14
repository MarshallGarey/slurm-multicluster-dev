#!/bin/bash
# start_clusters.sh
# Startup script for Slurm
# Print usage with ./start_clusters -h

# Get path to script: https://stackoverflow.com/a/1482133/4880288
install_path="$(dirname -- "$( readlink -f -- "$0"; )";)"
source "${install_path}/script_common.sh"

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

if [ $num_clusters -eq 1 ]
then
	echo "Starting cluster c1"
else
	echo "Starting clusters c[1-$num_clusters]"
fi

sudo ./stop_clusters.sh

# Start slurmdbd
"${install_path}"/sbin/slurmdbd
sleep 1

# Start slurmctld's
i=1
while [ $i -le $num_clusters ]
do
	if [ -z "${slurm_conf}" ]
	then
		SLURM_CONF="${install_path}/c$i/etc/slurm.conf"
	else
		SLURM_CONF="${slurm_conf}"
	fi
	"${install_path}"/sbin/slurmctld -f $SLURM_CONF $slurmctld_flags
	i=$(($i+1))
done

# Start slurmd's - start them all in parallel
i=1
while [ $i -le $num_clusters ]
do
	node_inx=1
	if [ -z "${slurm_conf}" ]
	then
		SLURM_CONF="${install_path}/c$i/etc/slurm.conf"
	else
		SLURM_CONF="${slurm_conf}"
	fi
	while [ $node_inx -le $num_nodes ]
	do
		nodename="n${i}-${node_inx}"
		echo "Start node ${nodename}"
		export NODE_NAME=${nodename}
		sudo --background --preserve-env=NODE_NAME "${install_path}"/sbin/slurmd -f $SLURM_CONF -N ${nodename}

		node_inx=$(($node_inx+1))
	done
	i=$(($i+1))
done

if [ $verbose -ne 0 ]
then
	set +x
fi
