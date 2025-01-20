#!/bin/bash
if [ $# -lt 1 ]
then
	echo "Expecting executable and arguments to the executable, for example:"
	echo "./use_valgrind.sh slurmctld -D -vvv"
	exit 1
fi
# Get timestamp in seconds.nanoseconds
tstampms="$(date +%s.%N)"
# Generate a hopefully unique filename
fname="valgrind-out-$(basename ${1})-${tstampms}.txt"
echo "Valgrind output filename: ${fname}"
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
	 --trace-children=yes \
	 --keep-debuginfo=yes \
         --verbose \
	 --log-file="${fname}" \
	 $@
