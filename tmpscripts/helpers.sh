#!/bin/bash
log="#INSTALL_PATH/c#CLUSTER/log/helpers.log"

nodename=$NODE_NAME
helpers_variable_file="#INSTALL_PATH/c#CLUSTER/scripts/${nodename}/helpers_variables"
if [ $# -eq 1 -a -n \"$1\" ]
then
	# Append features
	echo $1 >> ${helpers_variable_file}
else
	# Clear features
	printf "" > ${helpers_variable_file}
fi
cat ${helpers_variable_file}

printf "Run at $(date) with args: '$@'
NODE_NAME=$(printenv NODE_NAME)
helpers_variable_file=${helpers_variable_file}
cat ${helpers_variable_file}=
$(cat ${helpers_variable_file})
\n" >> $log
