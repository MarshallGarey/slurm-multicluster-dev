#!/bin/bash

#
# EDIT THIS SECTION:
#
# Each of these variables appears as "#<option_name>" in various configuration
# files and startup/shutdown scripts. Each of these variables must be set.
#
# user - Name of SlurmUser and used in file paths as the home directory.
user=marshall
# version - Slurm version. Used in file paths.
version=20.02
# db_name - Name of the database that slurmdbd will create.
db_name=slurm_2002
# Node hardware:
memory=8000
sockets=1
corespersocket=8
threadspercore=2

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
