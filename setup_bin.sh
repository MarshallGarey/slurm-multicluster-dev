#!/bin/sh
slurm_path='/home/#USER/slurm/#REPO_DIR/install'
i=1
while [ $i -le 3 ]
do
	c="$slurm_path/c$i"
	#echo $c
	mkdir $c/bin
	for f in `ls bin/`
	do
		script="$c/bin/$f"
		#echo $script
		printf "\
#!/bin/sh
export SLURM_CONF=$c/etc/slurm.conf
exec $slurm_path/bin/$f \"\$@\"
" > $script
		chmod 775 $script
	done
	i=$(($i+1))
done
