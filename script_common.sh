#!/bin/bash

function validate_number()
{
	if [ $# -ne 4 ]
	then
		echo "Expecting 4 arguments: <var to validate> <min value> <max value> <string desription or argument flag>"
		return -1
	fi
	num=$1
	min=$2
	max=$3
	arg_str=$4
	is_not_num_regex='[^0-9]+'

	if [[ $num =~ $is_not_num_regex || $num -gt $max || $num_clusters -lt $min ]]
	then
		echo "Error: Invalid argument $arg_str=$num: it must be between $min and $max, inclusive."
		exit 1
	fi
}
