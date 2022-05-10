#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/master/install"
curl -k -s -v \
	--request POST \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--data-binary @bug13956_account.json \
	--url localhost:8080/slurmdb/v0.0.38/accounts
