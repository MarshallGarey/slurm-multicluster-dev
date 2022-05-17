#!/bin/bash
source init.conf
#
# DO NOT EDIT THIS FILE
#
sed -i "s/#USER/$user/g" etc/slurmdbd.conf
sed -i "s/#VERSION/$version/g" etc/slurmdbd.conf
sed -i "s/#DB_NAME/$db_name/g" etc/slurmdbd.conf
sed -i "s/#PORT/$startingport/g" etc/slurmdbd.conf
sed -i "s/#USER/$user/g" start_clusters.sh
sed -i "s/#USER/$user/g" stop_clusters.sh
sed -i "s/#VERSION/$version/g" start_clusters.sh
sed -i "s/#VERSION/$version/g" stop_clusters.sh
sed -i "s/#BRANCH/$branch_name/g" init.sh
sed -i "s/#USER/$user/g" init_db.sh
sed -i "s/#USER/$user/g" setup_bin.sh
sed -i "s/#VERSION/$version/g" setup_bin.sh
sed -i "s/#USER/$user/g" init.sh
sed -i "s/#VERSION/$version/g" init.sh
for i in {1..3}
do
	file="c$i/etc/slurm.conf"
	sed -i "s/#USER/$user/g" $file
	sed -i "s/#VERSION/$version/g" $file
	sed -i "s/#MEMORY/$memory/g" $file
	sed -i "s/#SOCKETS/$sockets/g" $file
	sed -i "s/#CORES/$corespersocket/g" $file
	sed -i "s/#THREADS/$threadspercore/g" $file
	sed -i "s/#PORT/$startingport/g" $file
	file="c$i/etc/helpers.conf"
	sed -i "s/#USER/$user/g" $file
	sed -i "s/#VERSION/$version/g" $file
	for f in c$i/scripts/*
	do
		sed -i "s/#USER/$user/g" $f
		sed -i "s/#VERSION/$version/g" $f
	done
done
