#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/22.05/install"
curl -o "$SLURM_PATH/c1/log/curl.log" -k -s -v \
	--request PATCH \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.37/associations
#'http://localhost/slurmdb/v0.0.38/associations'
