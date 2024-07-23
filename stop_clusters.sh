#!/bin/bash

# Ensure that we have sudo privileges
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

# Get path to script: https://stackoverflow.com/a/1482133/4880288
install_path="$(dirname -- "$( readlink -f -- "$0"; )";)"

echo "Stopping Slurm"

# Are there any files in the directory (i.e., daemons are running)?
# -n flag for if means is not null
# -z flag for if means is null
if [ -n "`find ${install_path}/run ! -name '.gitignore' -type f`" ]
then
	printf "Stopping:\n`ls ${install_path}/run/`\n"
	for pid in `cat ${install_path}/run/*.pid`; do sudo kill -SIGTERM $pid; done
fi
# Max number of clusters is 9
for i in {1..9}
do
	p="${install_path}/c${i}"
	if [ ! -d "${p}" ]
	then
		continue
	fi
	if [ -n "$(find ${p}/run ! -name '.gitignore' -type f)" ]
	then
		printf "Stopping:\n$(ls ${p}/run/)\n"
		for pid in $(cat ${install_path}/c$i/run/*.pid); do sudo kill -SIGTERM $pid; done
	fi
done
