#!/bin/bash
sacctmgr=bin/sacctmgr
$sacctmgr -i add cluster discovery1 discovery2 discovery3
$sacctmgr -i add account acct1
$sacctmgr -i add user marshall account=acct1
$sacctmgr -i add fed discovery clusters=discovery1,discovery2,discovery3
