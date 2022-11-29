#!/bin/bash
num_args=$#
if [ $num_args -ne 1 ]
then
	conds='cluster=c1;account=acct1;user=marshall'
else
	conds=$@
fi
#echo "Looking for assoc matching: $conds"
curl -k -s \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.38/association?$conds \
#	| jq '.associations[] |
#	{
#		"cluster":.cluster,
#		"user":.user,
#		"account":.account,
#		"qos":.qos,
#		"max":.max
#	}'
