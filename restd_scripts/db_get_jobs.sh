#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/21.08/install"
#curl -o "$SLURM_PATH/c1/log/get_jobs.log" -k -s -vvvv \
curl -k -s -vv \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url "localhost:8080/slurmdb/v0.0.38/jobs/?$@" \
	| jq '.jobs[]|
	{
		job_id: .job_id, user: .user, state: .state.current,
		start: .time.start, end: .time.end
	}'
	#| jq '.jobs[]|{job_id: .job_id, container: .container, time: .time}'
	#--url localhost:8080/slurmdb/v0.0.38/jobs?partition=highprio

	#| jq '.jobs[]|{job_id: .job_id}'

