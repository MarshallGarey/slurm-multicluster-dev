#!/bin/sh
SLURM_PATH="/home/marshall/slurm-local/22.05/install"
curl -k -s -v \
	--request GET \
	-H X-SLURM-USER-NAME:$(whoami) \
	-H X-SLURM-USER-TOKEN:$SLURM_JWT \
	-H "Content-Type: application/json" \
	--url localhost:8080/slurm/v0.0.38/partitions \
#	|
#	jq '.partitions[]|
#{
#	"preemption_mode":.preemption_mode,
#	"name":.name,
#	"maximum_memory_per_cpu": .maximum_memory_per_cpu,
#	"maximum_memory_per_node": .maximum_memory_per_node
#}'
