#!/bin/sh
# Initialize all variables in scripts with configured values
# TODO: Test that variables have been initialized in init_conf_files.sh
./init_conf_files.sh
# We have setup.sh as a different file from init.sh because init_conf_files.sh
# modifies init.sh, which modification can't happen if init_conf_files.sh is
# called from init.sh.
./init.sh
