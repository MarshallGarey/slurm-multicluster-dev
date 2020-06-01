#!/bin/bash
# In slurmdbd.conf and slurm.conf file for each cluster, there are
# #USER and #VERSION strings. They are used to set SlurmUser and in various
# file paths.
# Set user and version here then run this script to replace those in the file.
# user needs to be the user (with a home directory) who cloned this repo.
# db_name will be the name of the database.
user=marshall
version=20.02
db_name=slurm_2002
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
	sed -i "s/#USER/$user/g" c$i/etc/slurm.conf
	sed -i "s/#VERSION/$version/g" c$i/etc/slurm.conf
done
