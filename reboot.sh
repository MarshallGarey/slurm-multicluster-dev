#!/bin/bash
log="/home/marshall/slurm/23.02/install/c1/log/reboot.log"
exec 2>&1
exec 1>>${log}
outstr="
================================================================================
$(date): Reboot Program.
arg0=$0
args:
'$@'
env:
$(env)
================================================================================
"
echo "$outstr"
$SUDO_COMMAND -b
