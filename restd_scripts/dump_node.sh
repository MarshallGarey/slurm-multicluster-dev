#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/22.05/install"
#curl -o "$SLURM_PATH/c1/log/curl.log" -k -s -vvvv \
curl -k -s -vvvv \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurm/v0.0.37/node/n1-1
