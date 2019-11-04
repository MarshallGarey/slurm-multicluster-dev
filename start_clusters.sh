#!/bin/bash

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

basepath="/home/marshall/slurm/master/install"
echo "starting clusters discovery1, discovery2, discovery3, base=$basepath"

# Start slurmdbd
$basepath/sbin/slurmdbd
sleep 3

# Start slurmctld's
for i in {1..3}
do
	SLURM_CONF="$basepath/discovery$i/etc/slurm.conf" $basepath/sbin/slurmctld
done

# Start slurmd's
for i in {1..10}
do
	sudo $basepath/sbin/slurmd -f $basepath/discovery1/etc/slurm.conf -Nd1_$i
	sudo $basepath/sbin/slurmd -f $basepath/discovery2/etc/slurm.conf -Nd2_$i
	sudo $basepath/sbin/slurmd -f $basepath/discovery3/etc/slurm.conf -Nd3_$i
done
