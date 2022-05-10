#!/bin/bash
log_file="/home/#USER/slurm/#VERSION/install/c1/log/powersave.log"
# Redirect all stdout/stderr to a log file
exec 2>&1
exec 1>>$log_file

echo "SUSPEND PROGRAM: ran at: `date`"
echo "All args:"
echo $@
printenv
#echo "Test sleeping for 15 seconds"
#sleep 15
echo ""
echo ""
