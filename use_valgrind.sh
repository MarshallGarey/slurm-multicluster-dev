#!/bin/bash
if [ $# -lt 1 ]
then
	echo "Expecting executable and arguments to the executable as an argument"
	exit 1
fi
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
	 --trace-children=yes \
	 --keep-debuginfo=yes \
         --verbose \
         --log-file=valgrind-out.txt \
	 $@
