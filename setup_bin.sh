#!/bin/bash
install_path=$(pwd)
if [ -n ${1} ]
then
	dest_path="${1}"
else
	dest_path="${install_path}"
fi
echo "${install_path}"
i=1
while [ $i -le 3 ]
do
	c="${install_path}/c$i"
	echo $c
	cd "${c}"
	# Setup the bin directory; each script will be a wrapper of the
	# actual binary file
	mkdir bin
	cd "${install_path}"
	for file in $(ls bin/)
	do
		script="${c}/bin/${file}"
		#echo $script
		printf "\
#!/bin/sh
export SLURM_CONF=${c}/etc/slurm.conf
exec ${dest_path}/bin/${file} \"\$@\"
" > $script
		chmod 775 $script
	done
	i=$((${i}+1))
done
