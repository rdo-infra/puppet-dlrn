#!/bin/bash
LOCK="/home/${USER}/dlrn.lock"
set -e

exec 200>$LOCK
flock -n 200 || exit 1

if [ ! -d /home/${USER}/dlrn-logs ]
then
    mkdir -p /home/${USER}/dlrn-logs
fi

source ~/.venv/bin/activate
LOGFILE=/home/${USER}/dlrn-logs/dlrn-run.$(date +%s).log
cd ~/dlrn

echo `date` "Starting DLRN run." >> $LOGFILE
dlrn --config-file /usr/local/share/dlrn/${USER}/projects.ini --info-repo /home/rdoinfo/rdoinfo/ 2>> $LOGFILE
echo `date` "DLRN run complete." >> $LOGFILE
