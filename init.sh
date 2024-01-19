#!/bin/bash

source init.conf
source script_common.sh

###############################################################################
# Functions
###############################################################################

function mkenvrc()
{
	envrc=".envrc"
	# envrc used to be a symlink. It isn't now. This rm will remove
	# the old symlink and ensure that it is a regular file.
	# This only matters for old setups that still have the symlink.
	rm "${envrc}"
	echo '# .envrc
# This file is used by direnv (https://direnv.net/).
# direnv needs to be hooked into the shell: https://direnv.net/docs/hook.html
# Once direnv is hooked into the shell, it automatically sets environment
# variables listed in .envrc.
SYSCONF=$(pwd)
export PATH=$SYSCONF/bin:$SYSCONF/sbin:$PATH
export MANPATH=$SYSCONF/share/man:$MANPATH
export SACCT_FORMAT="cluster,jobid,jobname%20,state,exitcode,submit,start,end,elapsed,eligible"
export SPRIO_FORMAT="%.15i %9r %.10Y %.10S %.10A %.10B %.10F %.10J %.10P %.10Q %30T"
export SLURMRESTD=$(which slurmrestd)' > "${envrc}"
}

function mkslurmdbd_conf()
{
	local slurmdbd_conf="${install_path}/etc/slurmdbd.conf"
	echo "#
# slurmdbd.conf
#

# Debug
DebugLevel=debug
LogFile=${install_path}/log/slurmdbd.log
PidFile=${install_path}/run/slurmdbd.pid

# Database info
StorageType=accounting_storage/mysql
StorageHost=localhost
DbdHost=localhost
DbdPort=${startingport}000
StorageLoc=${db_name}
SlurmUser=${slurm_user}
TrackWckey=yes

# Configurations
MessageTimeout=60
AuthAltTypes=auth/jwt
AuthAltParameters=jwt_key=${install_path}/jwt_hs256.key

# Purge and Archive
ArchiveDir=${install_path}/archive

#ArchiveEvents=yes
#ArchiveJobs=yes
#ArchiveResvs=yes
#ArchiveSteps=yes
#ArchiveSuspend=yes
#ArchiveTXN=yes
#ArchiveUsage=yes

#PurgeEventAfter=12hours
#PurgeJobAfter=12hours
#PurgeResvAfter=12hours
#PurgeStepAfter=12hours
#PurgeSuspendAfter=12hours
#PurgeTXNAfter=12hours
#PurgeUsageAfter=12hours
" > "${slurmdbd_conf}"

	chmod 600 etc/slurmdbd.conf
}

function mkjwt_key()
{
	local jwt_key="${install_path}/jwt_hs256.key"
	echo "nate likes tacos" > "${jwt_key}"
	chmod 600 "${jwt_key}"
}

function mkdirs_common()
{
	# Use -p so that no error occurs if the directory already exists,
	# which happens when init.sh is re-run after it has already been run
	mkdir -p etc
	mkdir -p log
	mkdir -p run
}

function cp_tmp_dir()
{
	if [ $# -ne 2 ]
	then
		echo "${FUNCNAME[0]} expects 2 args: clusterdir dirname"
		return -1
	fi

	local new="${1}/${2}"
	local t="$(date +%Y-%m-%dT%H:%M:%S)"
	local new_bk="${new}.bk.${t}"
	local tmp="tmp${2}"

	cd "${install_path}"
	mkdir -p "${new}"
	mkdir -p "${new_bk}"
	cd "${new_bk}"
	# Backup old files
	mv "${install_path}/${new}"/* "${install_path}/${new_bk}/"
	# Create new files
	cp -r "${install_path}/${tmp}"/* "${install_path}/${new}/"
	cd "${install_path}"
}

function clone_slurm()
{
	local p="${install_path}/../slurm"
	if [ -d "${p}" ]
	then
		# Already exists; pull latest changes
		cd "${p}"
		git pull
		cd -
		return
	fi
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
}

function build_slurm()
{
	cd "${install_path}"
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
		${makeme} --with-all --with-clean
	fi
}

function generate_cluster_dirs()
{
	i=1
	while [ $i -le ${num_clusters} ]
	do
		c="${install_path}/c$i"
		#echo $c
		# Make the cluster directory and any additional needed directories.
		mkdir -p "${c}"
		cd "${c}"
		mkdirs_common
		mkdir -p spool
		# Setup the bin directory; each script will be a wrapper of the
		# actual binary file
		mkdir -p bin
		cd "${install_path}"
		set +x
		echo "Generate cluster ${c} bin files"
		for file in $(ls bin/)
		do
			script="${c}/bin/${file}"
			#echo $script
			printf "\
#!/bin/sh
export SLURM_CONF=${c}/etc/slurm.conf
exec ${install_path}/bin/${file} \"\$@\"
" > $script
			chmod 775 $script
		done

		set -x
		# envrc
		cd "${c}"
		mkenvrc

		# Setup symlinks
		ln -sfr ../sbin sbin
		ln -sfr ../share share

		i=$((${i}+1))
	done
}

function generate_conf_scripts
{
	cd "${install_path}"

	# Generate slurmdbd.conf
	mkslurmdbd_conf

	i=1
	while [ $i -le ${num_clusters} ]
	do
		subs_in=("#CLUSTER" "#INSTALL_PATH" "#SLURM_USER" "#DB_NAME" "#PORT" "#MEMORY" "#SOCKETS" "#CORES" "#THREADS")
		subs_out=("${i}" "${install_path}" "${slurm_user}" "${db_name}" "${startingport}" "${memory}" "${sockets}" "${corespersocket}" "${threadspercore}")

		len=${#subs_in[@]}
		j=0

		# Configuration files
		cp_tmp_dir "c${i}" "etc"

		# Do text substitutions in config files
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
		cp_tmp_dir "c${i}" "spank"
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
		cp_tmp_dir "c${i}" "scripts"
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
		i=$((${i}+1))
	done
}

function print_usage()
{
	printf "\
Usage: init.sh [flags]
Flags:
-c: Skip configuring and compiling Slurm
-g: Skip git clone or pull
-h: Display this message
-p: Preserve exisiting Slurm configuration files and scripts
-r: Do not (re)generate cluster directories. This includes generating the cluster directories and the directories within (such as bin, etc, log, run).
"
}

###############################################################################
# Script start
###############################################################################

# Initialize options
skip_build=0
preserve_conf_scripts=0
skip_git=0
preserve_cluster_dirs=0
while getopts 'cghpr' flag
do
	case "${flag}" in
	c) skip_build=1 ;;
	g) skip_git=1 ;;
	h) print_usage; exit 1 ;;
	p) preserve_conf_scripts=1 ;;
	r) preserve_cluster_dirs=1;;
	*) # Default case
	   print_usage
	   exit 1 ;;
	esac
done

echo "skip_build=${skip_build}, preserve_conf_scripts=${preserve_conf_scripts}, skip_git=${skip_git}, preserve_cluster_dirs=${preserve_cluster_dirs}"

set -ex
# Get path to script: https://stackoverflow.com/a/1482133/4880288
install_path="$(dirname -- "$( readlink -f -- "$0"; )";)"

validate_number "${num_clusters}" 1 9 "num_clusters"

# Clone, then build and install Slurm
if [ ${skip_git} -eq 0 ]
then
	clone_slurm
fi
if [ ${skip_build} -eq 0 ]
then
	build_slurm
fi

# Setup directories for each cluster
cd "${install_path}"

# Create base directories
mkdirs_common

if [ ${preserve_cluster_dirs} -eq 0 ]
then
	generate_cluster_dirs
fi

cd "${install_path}"
mkenvrc

# Enable direnv
./allow_direnv.sh

# Generate jwt key
mkjwt_key

# Copy example scripts or conf files from the Slurm repo etc directory
tmpetc_p="${install_path}/tmpetc"
cd "${install_path}/../slurm/etc"
cp burst_buffer.lua.example "${tmpetc_p}/burst_buffer.lua"
cp cli_filter.lua.example "${tmpetc_p}/cli_filter.lua"
# I'm using my own, so don't copy from etc/
#cp job_submit.lua.example "${tmpetc_p}/job_submit.lua"

if [ ${preserve_conf_scripts} -eq 0 ]
then
	generate_conf_scripts
fi

# Add symlinks to c1/etc. c1 will act as the default cluster.
cd "${install_path}/c1/etc"
for f in *
do
	cd "${install_path}/etc"
	ln -sfr "../c1/etc/$f" "$f"
done

cd ${install_path}

# Setup testsuite
printf "# globals.local
set slurm_dir \"${install_path}\"
set build_dir \"${install_path}/build\"
#set testsuite_log_level \$LOG_LEVEL_TRACE
set testsuite_cleanup_on_failure false

# TODO: When uncommenting this, fix it to use num_clusters
#federation tests (test37.*) are all broken right now
#set fed_slurm_base \"${slurm_dir}\"
#set fedc1 \"c1\"
#set fedc2 \"c2\"
#set fedc3 \"c3\"
" > ../slurm/testsuite/expect/globals.local
cp build/testsuite/testsuite.conf.sample ../slurm/testsuite/testsuite.conf

# There must be at least one cluster configured. Build out the string
# for any additional clusters.
i=2
clusters="c1"
while [ $i -le ${num_clusters} ]
do
	clusters="${clusters} c${i}"
	i=$((${i}+1))
done
# Setup database
mkdir -p archive
export SLURM_CONF="${install_path}/etc/slurm.conf"
./sbin/slurmdbd
sleep 2 # Wait for slurmdbd to start
sacctmgr=bin/sacctmgr
# sacctmgr may error if the assocs already exist
set +e
# Do not surround ${clusters} with quotes since we want the
# different clusters to be space separated
${sacctmgr} -i add cluster ${clusters}
${sacctmgr} -i add account acct1
${sacctmgr} -i add user ${slurm_user} account=acct1
# Kill slurmdbd
set -e
kill $(cat run/slurmdbd.pid)

set +x
echo ""
echo ""
echo "Done!"
echo "Please add the following lines to the bottom of /etc/sudoers or an included file in /etc/sudoers.d/:"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/stop_node.sh"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/stop_clusters.sh"
echo "${slurm_user} ALL = (root) SETENV:NOPASSWD:${install_path}/sbin/slurmd"
