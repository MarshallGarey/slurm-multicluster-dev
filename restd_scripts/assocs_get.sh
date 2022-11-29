#!/bin/bash
curl -k -s \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.38/associations \
	| jq '.associations[] |
	{
		"cluster":.cluster,
		"user":.user,
		"account":.account,
		"qos":.qos,
		"max":.max
	}'
