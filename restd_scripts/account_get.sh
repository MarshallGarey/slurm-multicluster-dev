#!/bin/sh
curl -k -s \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurmdb/v0.0.38/account/$@ \

