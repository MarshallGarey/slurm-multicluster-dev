#!/bin/sh
PREFIX=/home/#USER/slurm/#VERSION/install/c2/
LOG=$PREFIX/log/mail.log

# Redirect all stdout and stderr to a log file!
exec 2>&1
exec 1>>$LOG

now=$(date)

echo "Mail $SLURM_JOB_MAIL_TYPE: ******************************************"
echo "Mail $SLURM_JOB_MAIL_TYPE: Job: $SLURM_JOB_ID"
echo "Mail $SLURM_JOB_MAIL_TYPE: Date: $now"
echo "Mail $SLURM_JOB_MAIL_TYPE: User: $SLURM_JOB_USER"
echo "Mail $SLURM_JOB_MAIL_TYPE: Mail Type: $SLURM_JOB_MAIL_TYPE"
echo "Mail $SLURM_JOB_MAIL_TYPE: Job State: $SLURM_JOB_STATE"
echo "Mail $SLURM_JOB_MAIL_TYPE: ******************************************"
echo ""
echo ""

