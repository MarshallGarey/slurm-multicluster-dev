# README
This is my development environment for Slurm. It sets up an environment to run
three clusters in Slurm.

## Setup
Create a directory for this repository:

`/home/username/slurm/dir_name/`

### Clone this repo
Clone this repository inside of the directory that was just created:

    git clone git@github.com:MarshallGarey/slurm-multicluster-dev.git install

### Initialize everything:
  * Open init.conf with your favorite text editor. Set the variables.
  * (Optional) Install [direnv](https://direnv.net/):
    * Install direnv with a package manager (e.g. sudo apt install direnv).
    * [Hook](https://direnv.net/docs/hook.html) direnv to your shell by
      following the directions on that website.
  * Run ./setup.sh

That's all you need to do!
The following sections explain how this process works in detail.

#### Slurm Configuration:
Open init.conf with your favorite text editor. Set the variables.
These values will be placed in various by init\_conf\_files.sh.
init.sh will clone Slurm in the parent directory of this repository.

#### How to build:
Assuming your Slurm version is "master":

    cd build
    ../../slurm/configure --prefix=/home/marshall/slurm/master/install --enable-developer --enable-multiple-slurmd --disable-optimizations --with-pam_dir=/home/marshall/slurm/master/install/lib
    make.py --with-all
    cd ..
    ./setup_bin.sh

I build with
[make.py](https://gitlab.com/bsngardner/slurm_devinst_scripts/blob/master/make.py),
written by Broderick Gardner. It's a great parallel build program designed
specifically for Slurm. If you don't want to use it, feel free to just run
`make -j install` instead. It will be a lot slower than `make.py`, however. I
also use
[ccache]([https://github.com/ccache/ccache](https://github.com/ccache/ccache))
to greatly speed up my compile time. Since I compile a lot and it often
recompiles code that hasn't changed, `ccache` makes a huge difference to
performance.

#### How to setup Slurm's database:
This is required before you can run Slurm.
Follow the directions at [Slurm's accounting page](https://slurm.schedmd.com/accounting.html) to setup the database.
Change the permissions of the slurmdbd.conf file to 600 (required by Slurm).
Start slurmdbd, then call init\_db.sh.

    # cd to the base of this repository
    mkdir archive
    chmod 600 etc/slurmdbd.conf
    ./sbin/slurmdbd
    export SLURM_CONF=`pwd`/etc/slurm.conf
    ./init_db.sh

This creates 3 clusters in the database named c1, c2, and c3.

## How to Start Slurm:

    sudo ./start_clusters.sh [num_clusters] ['slurmctld_flags']

The help/usage (./start\_clusters.sh -h) displays all the arguments.
This script calls ./stop\_clusters.sh first, then starts the Slurm daemons.

## How to Stop Slurm:

    sudo ./stop_clusters.sh

## Running Slurm commands:

### With direnv
The `bin` directory has all the Slurm commands.
Hook [direnv](https://direnv.net/) to your shell so that the `bin`. This will
add the `bin` directory for the appropriate cluster to your path. Then you can
`cd` to the cluster directory of your choice (`c1`, `c2`, or `c3`) and just run
a Slurm command:

    cd c1
    srun hostname
    cd ../c2
    srun hostname

If you are in the parent directory (`install`), then it defaults to `c1`.

### Without direnv
If you don't wish to use direnv, then do the following:
`cd` to the `bin` directory in the cluster (c1, c2, c3) that you want to run
commands from. For example, to submit a job from cluster c1:

    cd c1/bin
    ./srun hostname

I like adding the `bin` directory to my path.

    export PATH=`pwd`/c1/bin:$PATH

To make life easy, I have a function in my `.bashrc` file to setup the path and
also take advantage of Slurm's auto-completion script.

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
For example:

    cd c1
    setups
    srun hostname

### Automatically source the auto-completion script
If you are using `zsh`, then you can use the
[chpwd function](https://unix.stackexchange.com/a/683600/244332) to source
the `slurm_completion.sh` file.
If your shell does nt have `chpwd`, then you can redefine `cd`:
Add the following to `.bashrc` (or whatever the equivalent is for your shell):

    function chpwd()
    {
        if [ -f ../slurm/contribs/slurm_completion_help/slurm_completion.sh ]
        then
            source ../slurm/contribs/slurm_completion_help/slurm_completion.sh
        fi
    }

    function cd()
    {
        builtin cd $@
        chpwd
    }

You could also use this as an alternative to direnv and .envrc.
