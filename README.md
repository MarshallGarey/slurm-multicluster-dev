# README
This is my multi-cluster/federation environment for Slurm.

## Slurm Configuration:
Open init\_conf\_files.sh with your favorite text editor. Set the variables
user, version, and db\_name, following the guidelines in the script. Then close
this file and run it. This will ensure the various scripts and configurations
files have the correct username, file paths, and database name.
Note: This doesn't change the ports. You will have to manually change
SlurmctldPort, AccountingStoragePort, and the ports for the nodes if these
ports are already being used. TODO: Make a way to change these ports with
init\_conf\_files.sh.

## How to build:
Assuming your Slurm version is "master":

    cd ~/
    mkdir slurm
    cd slurm
    mkdir master
    cd master
    # Clone Slurm
    git clone git@github.com:SchedMD/slurm.git slurm
    # Clone this repo
    git clone git@github.com:MarshallGarey/slurm-multicluster-dev.git install
    # Build and install Slurm
    mkdir install/build install/lib
    cd install/build
    ../../slurm/configure --prefix=/home/marshall/slurm/master/install --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir=/home/marshall/slurm/master/install/lib
    make.py
    ./setup_bin.sh

I build with [make.py](https://gitlab.com/bsngardner/slurm_devinst_scripts/blob/master/make.py), written by Broderick Gardner. It's a great parallel build program designed specifically for Slurm. If you don't want to use it, feel free to just run `make -j install` instead. It will be a lot slower than `make.py`, however. I also use [ccache]([https://github.com/ccache/ccache](https://github.com/ccache/ccache)) to greatly speed up my compile time. Since I compile a lot and it often recompiles code that hasn't changed, `ccache` makes a huge difference to performance. `ccache` plus Broderick's `make.py` has reduced my compile time from 40+ seconds down to less than 10 seconds. Your mileage may vary depending on your hardware.

## How to setup Slurm's database:
This is required before you can run Slurm.
Follow the directions at [Slurm's accounting page](https://slurm.schedmd.com/accounting.html) to setup the database.
Change the permissions of the slurmdbd.conf file to 600 (required by Slurm).
Start slurmdbd, then call init\_db.sh.

    cd ../etc
    chmod 600 slurmdbd.conf
    cd ../sbin
    ./slurmdbd
    cd ..
    export SLURM_CONF=`pwd`/etc/slurm.conf
    ./init_db.sh

This creates 3 clusters in the database named c1, c2, and c3.

## How to Start Slurm:

    sudo ./start_clusters.sh

## How to Stop Slurm:

    sudo ./stop_clusters.sh

## Running Slurm commands:

`cd` to the cluster (c1, c2, c3) that you want to run commands from. Set the path to the slurm.conf file of that cluster to the environment variables `SLURM_CONF`. `cd` to `bin` and run any Slurm command. For example, to submit a job from cluster c1:

    cd c1
    export SLURM_CONF=`pwd`/etc/slurm.conf
    cd bin
    ./srun hostname

Optionally you can add `bin` to the path, then you can run client commands from any directory.

    export PATH=`pwd`/bin:$PATH

I simply added these things to a function in my `.bashrc` file called `setups`. Here it is:

    #.bashrc
    function setups
    {
    	SYSCONF=`pwd`
    	export PATH=$SYSCONF/bin:$SYSCONF/sbin:$PATH
    	export MANPATH=$SYSCONF/share/man:$MANPATH
    	source ../slurm/contribs/slurm_completion_help/slurm_completion.sh
    	export SLURM_CONF=$SYSCONF/etc/slurm.conf
    }

Then I run `setups` from c1, c2, or c3, then run any Slurm client command.
