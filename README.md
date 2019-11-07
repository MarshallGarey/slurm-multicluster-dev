
# README
This is my multi-cluster/federation environment for Slurm. Please report any bugs to me.

Unfortunately, I've hardcoded my path into the scripts and slurm.conf files. I've also hard-coded in the cluster names and the database name. I welcome edits to make this more generic.

## How to build:

    cd /home/marshall/slurm
    mkdir master
    cd master
    git clone git@github.com:MarshallGarey/slurm-multicluster-dev.git install
    mkdir install/build
    cd install/build
    ../../slurm/configure --prefix=/home/marshall/slurm/master/install --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir=/home/marshall/slurm/master/install/lib
    make.py

I build with [make.py](https://gitlab.com/bsngardner/slurm_devinst_scripts/blob/master/make.py), written by Broderick Gardner. It's a great parallel build program designed specifically for Slurm. If you don't want to use it, feel free to just run `make -j install` instead. It will be a lot slower than `make.py`, however. I also use [ccache]([https://github.com/ccache/ccache](https://github.com/ccache/ccache)) to greatly speed up my compile time. Since I compile a lot and it often recompiles code that hasn't changed, `ccache` makes a huge difference to performance. `ccache` plus Broderick's `make.py` has reduced my compile time from 40+ seconds down to less than 10 seconds. Your mileage may vary depending on your hardware.

## How to start Slurm:
Follow the directions at [Slurm's accounting page](https://slurm.schedmd.com/accounting.html) to setup the database. Then:

    cd ../sbin
    ./slurmdbd
    cd ../discovery1
    export SLURM_CONF=`pwd`/slurm.conf
    ./init_db.sh
    cd ..
    ./start_clusters.sh

This creates 3 clusters in the database named discovery1, discovery2, and discovery3.
init_db.sh will create a federation with sacctmgr of all 3 clusters.

## How to Stop Slurm:

    ./stop_clusters.sh

## Running Slurm commands:

`cd` to the cluster (discovery1, discovery2, discovery3) that you want to run commands from. Set the path to the slurm.conf file of that cluster to the environment variables `SLURM_CONF`. cd to `bin` and run any Slurm command. For example, to submit a job from discovery1:

    cd discovery1
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

Then I run `setups` from discovery1, discovery2, or discovery3.
