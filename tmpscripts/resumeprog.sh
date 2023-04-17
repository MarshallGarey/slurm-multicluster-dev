#!/bin/bash
install_dir="#INSTALL_PATH"
cluster="c#CLUSTER"
log_file="${install_dir}/${cluster}/log/powersave.log"
bin_dir="${install_dir}/${cluster}/bin"
# Redirect all stdout/stderr to a log file
exec 2>&1
exec 1>>$log_file

echo "RESUME PROGRAM: ran at: $(date)"
echo "All args:"
echo $@
printenv
if [ $SLURM_RESUME_FILE ]
then
	echo "Resume file contents:"
	cat $SLURM_RESUME_FILE
	echo ""
fi
for n in $("${bin_dir}/scontrol" show hostnames $@)
do
	echo "Start node $n"
	echo "sudo ${install_dir}/sbin/slurmd -N${n} -b"
	sudo NODE_NAME="${n}" ${install_dir}/sbin/slurmd -N${n} -b
done
#echo "Test sleeping for 15 seconds"
#sleep 15
echo ""
echo ""
