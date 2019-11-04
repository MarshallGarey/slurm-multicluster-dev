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
echo "stopping clusters discovery1, discovery2, discovery3, base=$basepath"

# Are there any files in the directory (i.e., daemons are running)?
# -prune means don't descend into the directory
# -empty means "file is empty and is either a regular file or directory"
if [ -z "$(find $basepath/run -prune -empty)" ]
then
	for pid in `cat $basepath/run/*.pid`; do sudo kill $pid; done
fi
for i in {1..3}
do
	if [ -z "$(find $basepath/discovery$i/run -prune -empty)" ]
	then
		for pid in `cat $basepath/discovery$i/run/*.pid`; do sudo kill $pid; done
	fi
done
