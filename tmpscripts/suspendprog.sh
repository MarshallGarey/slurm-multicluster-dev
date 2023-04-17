#!/bin/bash
install_dir="#INSTALL_PATH"
cluster="c#CLUSTER"
log_file="${install_dir}/${cluster}/log/powersave.log"
bin_dir="${install_dir}/${cluster}/bin"
# Redirect all stdout/stderr to a log file
exec 2>&1
exec 1>>$log_file

echo "SUSPEND PROGRAM: ran at: $(date)"
echo "All args:"
echo $@
printenv

for n in $("${bin_dir}/scontrol" show hostnames $@)
do
	echo "kill node $n"
	echo "sudo ${install_dir}/stop_node.sh ${n} c1"
	sudo ${install_dir}/stop_node.sh "${n}" "c1"
done
#echo "Test sleeping for 15 seconds"
#sleep 15
echo ""
echo ""
