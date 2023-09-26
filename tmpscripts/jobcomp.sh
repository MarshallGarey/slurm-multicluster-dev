#!/bin/bash
prefix="#INSTALL_PATH/c#CLUSTER/"
log="${prefix}/log/jobcomp.log"

# Redirect all stdout and stderr to a log file!
exec 2>&1
exec 1>>"${log}"

# Comment out exit 0 to see output in the log file.
exit 0

now=$(date)

echo "JobComp ******************************************"
echo "JobComp Job: ${JOBID}"
echo "JobComp Date: ${now}"
echo "JobComp User: ${USERNAME}"
echo "JobComp Partition: ${PARTITION}"
echo "JobComp QOS: ${QOS}"
echo "JobComp Job State: ${JOBSTATE}"
echo "JobComp Job Exit Code: ${EXITCODE}"
echo "JobComp ******************************************"

echo ""
echo ""
