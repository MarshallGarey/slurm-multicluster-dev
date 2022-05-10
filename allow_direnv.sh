#!/bin/sh
direnv allow
i=1
while [ $i -le 3 ]
do
	cd c$i
	direnv allow
	cd ..
	i=$((i+1))
done
