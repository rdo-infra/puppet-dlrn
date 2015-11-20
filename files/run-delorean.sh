#!/bin/bash
LOCK="/home/${USER}/delorean.lock"
set -e

exec 200>$LOCK
flock -n 200 || exit 1

if [ ! -d /home/${USER}/delorean-logs ]
then
    mkdir -p /home/${USER}/delorean-logs
fi

source ~/.venv/bin/activate
LOGFILE=/home/${USER}/delorean-logs/delorean-run.$(date +%s).log
cd ~/delorean

echo `date` "Starting delorean run." >> $LOGFILE
delorean --config-file /usr/local/share/delorean/${USER}/projects.ini --info-repo /home/rdoinfo/rdoinfo/ --head-only 2>> $LOGFILE
echo `date` "Delorean run complete." >> $LOGFILE
