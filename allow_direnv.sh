#!/bin/sh
direnv allow
for i in {1..3}
do
	cd c$i
	direnv allow
	cd ..
done
