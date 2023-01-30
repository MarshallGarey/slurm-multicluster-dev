#!/bin/bash
set -x
install_path=$(pwd)

./allow_direnv.sh
source init.conf

# Clone, then build and install Slurm
if [ -z "${branch_name}" ]
then
	git clone git@github.com:SchedMD/slurm.git ../slurm
else
	git clone --single-branch -b "${branch_name}" git@github.com:SchedMD/slurm.git ../slurm
fi
mkdir -p build lib
cd build
../../slurm/configure --prefix="${install_path}" --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir="${install_path}/lib"
# Build and install
makeme=$(which make.py)
rc=$?
if [ ${rc} -ne 0 ]
then
	make -j install
else
	${makeme} --with-all
fi
# Setup bin directories for each cluster
cd ..
slurm_path="$(pwd)"
i=1
while [ $i -le 3 ]
do
	c="${slurm_path}/c$i"
	#echo $c
	mkdir ${c}/bin
	for file in $(ls bin/)
	do
		script="${c}/bin/${file}"
		#echo $script
		printf "\
#!/bin/sh
export SLURM_CONF=${c}/etc/slurm.conf
exec ${slurm_path}/bin/${file} \"\$@\"
" > $script
		chmod 775 $script
	done
	i=$((${i}+1))
done

# Do text substitutions and copy etc and scripts directories to each cluster
sed -i "s@#INSTALL_PATH@${install_path}@g" etc/slurmdbd.conf
sed -i "s@#INSTALL_PATH@${install_path}@g" start_slurmds.sh
sed -i "s@#INSTALL_PATH@${install_path}@g" start_clusters.sh
sed -i "s@#INSTALL_PATH@${install_path}@g" stop_clusters.sh
sed -i "s@#SLURM_USER@${slurm_user}@g" etc/slurmdbd.conf
sed -i "s@#DB_NAME@$db_name@g" etc/slurmdbd.conf
sed -i "s@#PORT@$startingport@g" etc/slurmdbd.conf
sed -i "s@#SLURM_USER@${slurm_user}@g" start_clusters.sh
sed -i "s@#SLURM_USER@${slurm_user}@g" stop_clusters.sh
for i in {1..3}
do
	subs_in=("#CLUSTER" "#INSTALL_PATH" "#SLURM_USER" "#DB_NAME" "#PORT" "#MEMORY" "#SOCKETS" "#CORES" "#THREADS")
	subs_out=("${i}" "${install_path}" "${slurm_user}" "${db_name}" "${startingport}" "${memory}" "${sockets}" "${corespersocket}" "${threadspercore}")

	len=${#subs_in[@]}
	j=0

	# Configuration files
	cd "${install_path}"
	cp -r tmpetc c${i}/
	mv c${i}/tmpetc c${i}/etc
	cd "${install_path}/c${i}/etc"

	while [ ${j} -lt ${len} ]
	do
		# grep -d skip (--directory=skip): skip directories
		# grep -l (--files-with-matches): print only file names
		for file in $(grep -d skip -l "${subs_in[${j}]}" *)
		do
			sed -i "s@${subs_in[${j}]}@${subs_out[${j}]}@g" ${file}
		done
		j=$((${j}+1))
	done

	# Scripts
	cd "${install_path}"
	cp -r tmpscripts c${i}/
	mv c${i}/tmpscripts c${i}/scripts
	cd "${install_path}/c${i}/scripts"
	for file in $(grep -d skip -l "#INSTALL_PATH" *)
	do
		sed -i "s@#INSTALL_PATH@${install_path}@g" ${file}
	done
	for file in $(grep -d skip -l "#CLUSTER" *)
	do
		sed -i "s@#CLUSTER@${i}@g" ${file}
	done
done
cd ${install_path}


# Setup testsuite
printf "# globals.local
set slurm_dir \"${install_path}\"
set build_dir \"${slurm_dir}/build\"
#set testsuite_log_level $LOG_LEVEL_TRACE
set testsuite_cleanup_on_failure false

#federation tests (test37.*) are all broken right now
#set fed_slurm_base \"${slurm_dir}\"
#set fedc1 \"c1\"
#set fedc2 \"c2\"
#set fedc3 \"c3\"
" > ../slurm/testsuite/expect/globals.local
cp build/testsuite/testsuite.conf.sample ../slurm/testsuite/testsuite.conf

# Setup database
mkdir -p archive
export SLURM_CONF="${install_path}/etc/slurm.conf"
chmod 600 etc/slurmdbd.conf
./sbin/slurmdbd
sleep 2 # Wait for slurmdbd to start
sacctmgr=bin/sacctmgr
${sacctmgr} -i add cluster c1 c2 c3
${sacctmgr} -i add account acct1
${sacctmgr} -i add user ${slurm_user} account=acct1
#$sacctmgr} -i add fed discovery clusters=discovery1,discovery2,discovery3
# Kill slurmdbd
kill $(cat run/slurmdbd.pid)

echo "Done!"
