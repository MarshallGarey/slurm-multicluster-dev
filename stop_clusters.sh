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

echo "stopping clusters c1, c2, c3, install path=${install_path}"

# Are there any files in the directory (i.e., daemons are running)?
# -n flag for if means is not null
# -z flag for if means is null
if [ -n "`find ${install_path}/run ! -name '.gitignore' -type f`" ]
then
	printf "Stopping:\n`ls ${install_path}/run/`\n"
	for pid in `cat ${install_path}/run/*.pid`; do sudo kill -SIGINT $pid; done
fi
for i in {1..3}
do
	if [ -n "`find ${install_path}/c$i/run ! -name '.gitignore' -type f`" ]
	then
		printf "Stopping:\n`ls ${install_path}/c$i/run/`\n"
		for pid in `cat ${install_path}/c$i/run/*.pid`; do sudo kill -SIGINT $pid; done
	fi
done
