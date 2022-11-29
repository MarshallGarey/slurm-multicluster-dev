#!/bin/bash
source ../../.envrc
sacctmgr -i delete qos low
printf "
#############################################
Adding qos low...
#############################################
"
../qos_add.sh qos.json
printf "
#############################################
Getting qos low...
#############################################
"
../qos_get.sh low
#sacctmgr -i delete qos low
printf "
#############################################
Modifying qos low...
#############################################
"
../qos_add.sh qos2.json
printf "
#############################################
Getting qos low...
#############################################
"
../qos_get.sh low
#rest -s --data-binary @qos.json -H "Content-Type:application/json" 'http://a/slurmdb/v0.0.38/qos/' >/dev/null
#rest -s 'http://a/slurmdb/v0.0.38/qos/low'|jq '.QOS[] | {"preempt":.preempt, "flags": .flags}'
#rest -s --data-binary @qos2.json -H "Content-Type:application/json" 'http://a/slurmdb/v0.0.38/qos/' >/dev/null
#rest -s 'http://a/slurmdb/v0.0.38/qos/low'|jq '.QOS[] | {"preempt":.preempt, "flags": .flags}'
