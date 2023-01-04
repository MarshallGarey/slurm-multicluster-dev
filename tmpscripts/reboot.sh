#!/bin/bash
log="#INSTALL_PATH/c#CLUSTER/log/reboot.log"
exec 2>&1
exec 1>>$log
outstr="
================================================================================
$(date): Reboot Program.
args:
$@
nodename:
${NODE_NAME}
env:
$(env)
================================================================================
"
echo "$outstr"
# Restart the slurmd with -b
${SUDO_COMMAND} -b
