#!/bin/sh
gcc -Wall -Werror -g -shared spank.c -o spank.so -fPIC \
	-I#INSTALL_PATH/include \
	-Wl,-rpath=#INSTALL_PATH/lib \
	-L#INSTALL_PATH/lib -lslurm

