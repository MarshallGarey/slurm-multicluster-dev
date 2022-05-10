#!/bin/bash
#echo "hf1"
#echo "hf2"


helpers_variable_file=/home/#USER/slurm/#VERSION/install/c2/scripts/helpers_variables
touch $helpers_variable_file
if [ -n \"$1\" ]; then
	echo $1 > $helpers_variable_file
fi
cat $helpers_variable_file
