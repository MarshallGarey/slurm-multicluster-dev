#!/bin/bash

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

basepath="/home/#USER/slurm/#VERSION/install"
echo "starting clusters c1, c2, c3, base=$basepath"

# Start slurmdbd
sudo -u #USER $basepath/sbin/slurmdbd
sleep 1

# Start slurmctld's
for i in {1..3}
do
	SLURM_CONF="$basepath/c$i/etc/slurm.conf"
	sudo -u #USER SLURM_CONF=$SLURM_CONF $basepath/sbin/slurmctld -f $SLURM_CONF
done

# Start slurmd's
for i in {1..10}
do
	sudo $basepath/sbin/slurmd -f $basepath/c1/etc/slurm.conf -Nd1_$i
	sudo $basepath/sbin/slurmd -f $basepath/c2/etc/slurm.conf -Nd2_$i
	sudo $basepath/sbin/slurmd -f $basepath/c3/etc/slurm.conf -Nd3_$i
done
