#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/master/install"
#curl -o "$SLURM_PATH/c1/log/curl.log" -k -s -vvvv \
curl -k -s \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.38/associations \
		| jq -c '.associations[] | .qos'
