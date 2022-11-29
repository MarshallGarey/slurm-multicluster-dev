#!/bin/bash
num_args=$#
if [ $num_args -ne 1 ]
then
	echo "Must pass a file name where the file is the association to add in JSON"
	exit 1
fi
curl -k -s -vvvvv \
	--request POST \
	--data-binary @$@ \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.38/associations

