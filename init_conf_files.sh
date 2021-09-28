#!/bin/bash

#
# EDIT THIS SECTION:
#
# Each of these variables appears as "#<option_name>" in various configuration
# files and startup/shutdown scripts. Each of these variables must be set.
#
# user - Name of SlurmUser and used in file paths as the home directory.
user=#USER
# version - Slurm version. Used in file paths.
version=#VERSION
# db_name - Name of the database that slurmdbd will create.
db_name=#DB_NAME
# Node hardware:
memory=#MEMORY
sockets=#SOCKETS
corespersocket=#CORES
threadspercore=#THREADS

#
# DO NOT EDIT THIS SECTION:
#
sed -i "s/#USER/$user/g" etc/slurmdbd.conf
sed -i "s/#VERSION/$version/g" etc/slurmdbd.conf
sed -i "s/#DB_NAME/$db_name/g" etc/slurmdbd.conf
sed -i "s/#USER/$user/g" start_clusters.sh
sed -i "s/#USER/$user/g" stop_clusters.sh
sed -i "s/#VERSION/$version/g" start_clusters.sh
sed -i "s/#VERSION/$version/g" stop_clusters.sh
sed -i "s/#USER/$user/g" init_db.sh
for i in {1..3}
do
	file="c$i/etc/slurm.conf"
	sed -i "s/#USER/$user/g" $file
	sed -i "s/#VERSION/$version/g" $file
	sed -i "s/#MEMORY/$memory/g" $file
	sed -i "s/#SOCKETS/$sockets/g" $file
	sed -i "s/#CORES/$corespersocket/g" $file
	sed -i "s/#THREADS/$threadspercore/g" $file
done
