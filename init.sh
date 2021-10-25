#!/bin/sh

# Build and install Slurm
mkdir build lib
cd build
../../slurm/configure --prefix=/home/#USER/slurm/#VERSION/install --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir=/home/#USER/slurm/#VERSION/install/lib
# Install: first get make.py, then make.
wget https://gitlab.com/bsngardner/slurm_devinst_scripts/-/raw/master/make.py
chmod 775 make.py
./make.py --with-all
# Setup bin directories for each cluster
cd ..
./setup_bin.sh

# Setup database
export SLURM_CONF=`pwd`/etc/slurm.conf
chmod 600 etc/slurmdbd.conf
./sbin/slurmdbd
sleep 2 # Wait for slurmdbd to start
./init_db.sh
# Kill slurmdbd
kill `cat run/slurmdbd.pid`
