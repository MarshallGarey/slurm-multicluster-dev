#!/bin/bash

rest -vvvv --data-binary @account.json -H Content-Type:application/json -X POST 'http://localhost/slurmdb/v0.0.38/accounts'
