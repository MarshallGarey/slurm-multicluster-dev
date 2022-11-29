#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/22.05/install"
#curl -o "$SLURM_PATH/c1/log/curl.log" -k -s -vvvv \
curl -k -s  \
	--request POST \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurm/v0.0.38/job/submit \
	-d @run_het_job.json
	#-d '{"job":{"name":"restd-test","environment":{"PATH":"/bin:/usr/bin/:/usr/local/bin/:/home/marshall/slurm/22.05/install/c1/bin"}},"script":"#!/bin/bash\n srun sleep 10"}'

