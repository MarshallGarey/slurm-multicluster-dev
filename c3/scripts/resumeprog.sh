#!/bin/bash
log_file="/home/marshall/slurm/master/install/c3/log/powersave.log"
# Redirect all stdout/stderr to a log file
exec 2>&1
exec 1>>$log_file

echo "RESUME PROGRAM: ran at: `date`"
echo "All args:"
echo $@
printenv
if [ $SLURM_RESUME_FILE ]
then
	echo "Resume file contents:"
	cat $SLURM_RESUME_FILE
	echo ""
fi
#echo "Test sleeping for 15 seconds"
#sleep 15
echo ""
echo ""
