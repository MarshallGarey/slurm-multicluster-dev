#!/bin/sh

# Clone, then build and install Slurm
git clone --single-branch -b #BRANCH git@github.com:SchedMD/slurm.git ../slurm
mkdir build lib
cd build
../../slurm/configure --prefix=/home/#USER/slurm/#REPO_DIR/install --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir=/home/#USER/slurm/#REPO_DIR/install/lib
# Build and install
makeme=$(which make.py)
rc=$?
if [ $rc -ne 0 ]
then
	make -j install
else
	$makeme --with-all
fi
# Setup bin directories for each cluster
cd ..
./setup_bin.sh

# Setup testsuite
printf '# globals.local
set base "/home/#USER/slurm/#REPO_DIR"
set slurm_dir "${base}/install"
set build_dir "${slurm_dir}/build"
#set testsuite_log_level $LOG_LEVEL_TRACE
set testsuite_cleanup_on_failure false

#federation tests (test37.*) are all broken right now
#set fed_slurm_base "$slurm_dir"
#set fedc1 "c1"
#set fedc2 "c2"
#set fedc3 "c3"
' > ../slurm/testsuite/expect/globals.local

# Setup database
mkdir archive
export SLURM_CONF=`pwd`/etc/slurm.conf
chmod 600 etc/slurmdbd.conf
./sbin/slurmdbd
sleep 2 # Wait for slurmdbd to start
./init_db.sh
# Kill slurmdbd
kill `cat run/slurmdbd.pid`
