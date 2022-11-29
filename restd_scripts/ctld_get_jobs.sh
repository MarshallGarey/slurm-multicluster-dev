#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/21.08/install"
curl -k -s -v \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurm/v0.0.38/jobs \
	| jq '.jobs[]|{job_id: .job_id, user_id: .user_id, user_name: .user_name, group: .group_name, job_state: .job_state, container: .container}'
	#| jq '.jobs[]|{job_id: .job_id, user_id: .user_id, user_name: .user_name, job_state: .job_state, container: .container}'
