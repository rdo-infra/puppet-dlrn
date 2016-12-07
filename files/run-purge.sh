#!/bin/bash
LOCK="/home/${USER}/dlrn.lock"
set -e

# if any arguments are given, assume console foreground execution
ARG=$1

exec 200>$LOCK
while !  flock -n 200; do
    if [ -n "$ARG" ]
    then
        echo "DLRN ${USER} running, waiting 30 seconds before retrying."
    fi
    sleep 30
done

if [ ! -d /home/${USER}/dlrn-logs ]; then
    mkdir -p /home/${USER}/dlrn-logs
fi

source ~/.venv/bin/activate
if [ -n "$ARG" ]; then
    LOGFILE=/home/${USER}/dlrn-logs/dlrn-purge.console.$(date +%s).log
    ARGUMENTS=""
else
    LOGFILE=/home/${USER}/dlrn-logs/dlrn-purge.$(date +%s).log
    ARGUMENTS="--older-than 60 -y --exclude-dirs /home/${USER}/data/repos/current,/home/${USER}/data/repos/consistent,/home/${USER}/data/repos/current-passed-ci,/home/${USER}/data/repos/current-tripleo"
fi
cd ~/dlrn

set +e
echo `date` "Starting DLRN-purge run." >> $LOGFILE
dlrn-purge --config-file /usr/local/share/dlrn/${USER}/projects.ini "${ARGUMENTS}" "$@" 2>> $LOGFILE
RET=$?
echo `date` "DLRN-purge run complete." >> $LOGFILE

if [ -n "$ARG" ]; then
    echo Arguments: "$@"
    cat $LOGFILE
fi
exit $RET
