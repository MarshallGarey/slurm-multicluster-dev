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
echo "stopping clusters c1, c2, c3, base=$basepath"

# Are there any files in the directory (i.e., daemons are running)?
# -n flag for if means is not null
# -z flag for if means is null
if [ -n "`find $basepath/run ! -name '.gitignore' -type f`" ]
then
	printf "Stopping:\n`ls $basepath/run/`\n"
	for pid in `cat $basepath/run/*.pid`; do sudo kill $pid; done
fi
for i in {1..3}
do
	if [ -n "`find $basepath/c$i/run ! -name '.gitignore' -type f`" ]
	then
		printf "Stopping:\n`ls $basepath/c$i/run/`\n"
		for pid in `cat $basepath/c$i/run/*.pid`; do sudo kill $pid; done
	fi
done
