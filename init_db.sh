#!/bin/bash
sacctmgr=bin/sacctmgr
$sacctmgr -i add cluster c1 c2 c3
$sacctmgr -i add account acct1
$sacctmgr -i add user #USER account=acct1
#$sacctmgr -i add fed discovery clusters=discovery1,discovery2,discovery3
