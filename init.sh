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
	count=$(git ls-remote --heads https://github.com/SchedMD/slurm.git "${branch_name}" | wc -l)
	if [ "${count}" -ne 1 ]
	then
		echo "Specified Slurm branch \"${branch_name}\" does not exist."
		exit -1
	fi
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

# Copy example scripts or conf files from the Slurm repo etc directory
tmpetc_p="${install_path}/tmpetc"
cd "${install_path}/../slurm/etc"
cp burst_buffer.lua.example "${tmpetc_p}/burst_buffer.lua"
cp cli_filter.lua.example "${tmpetc_p}/cli_filter.lua"
cp job_submit.lua.example "${tmpetc_p}/job_submit.lua"

# Do text substitutions and copy directories to each cluster
cd "${install_path}"
sed -i "s@#INSTALL_PATH@${install_path}@g" etc/slurmdbd.conf
sed -i "s@#INSTALL_PATH@${install_path}@g" start_slurmds.sh
sed -i "s@#INSTALL_PATH@${install_path}@g" start_clusters.sh
sed -i "s@#INSTALL_PATH@${install_path}@g" stop_clusters.sh
sed -i "s@#INSTALL_PATH@${install_path}@g" stop_node.sh
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
	rm -rf c${i}/etc
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

	# SPANK
	cd "${install_path}"
	cp -r tmpspank c${i}/
	rm -rf c${i}/spank
	mv c${i}/tmpspank c${i}/spank
	cd c${i}/spank
	for file in $(grep -d skip -l "#INSTALL_PATH" *)
	do
		sed -i "s@#INSTALL_PATH@${install_path}@g" ${file}
	done
	for file in $(grep -d skip -l "#CLUSTER" *)
	do
		sed -i "s@#CLUSTER@${i}@g" ${file}
	done

	# Scripts
	cd "${install_path}"
	cp -r tmpscripts c${i}/
	rm -rf c${i}/scripts
	mv c${i}/tmpscripts c${i}/scripts
	cd "${install_path}/c${i}/scripts"
	# Powersave scripts need non-world/group write permissions
	chmod 755 *.sh
	for file in $(grep -d skip -l "#INSTALL_PATH" *)
	do
		sed -i "s@#INSTALL_PATH@${install_path}@g" ${file}
	done
	for file in $(grep -d skip -l "#CLUSTER" *)
	do
		sed -i "s@#CLUSTER@${i}@g" ${file}
	done
done

# Add symlinks to c1/etc. c1 will act as the default cluster.
cd "${install_path}/c1/etc"
for f in *
do
	cd "${install_path}/etc"
	ln -sr "../c1/etc/$f" "$f"
done

cd ${install_path}

# Setup testsuite
printf "# globals.local
set slurm_dir \"${install_path}\"
set build_dir \"${install_path}/build\"
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

set +x
echo ""
echo ""
echo "Done!"
echo "Please add the following lines to the bottom of /etc/sudoers or an included file in /etc/sudoers.d/:"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/stop_node.sh"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/stop_clusters.sh"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/sbin/slurmd"
