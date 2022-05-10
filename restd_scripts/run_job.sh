#!/bin/bash
SLURM_PATH="/home/marshall/slurm-local/master/install"
curl -o "$SLURM_PATH/c1/log/curl.log" -k -s -vvvv \
	--request POST \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurm/v0.0.37/job/submit \
	-d '{"job":{"name":"restd-test","environment":{"PATH":"/bin:/usr/bin/:/usr/local/bin/:/home/marshall/slurm/master/install/c1/bin"}},"script":"#!/bin/bash\n srun sleep 60"}'

