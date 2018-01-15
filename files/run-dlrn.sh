#!/bin/bash
LOCK="/home/${USER}/dlrn.lock"
set -e

# if any arguments are given, assume console foreground execution
ARG=$1

exec 200>$LOCK
if !  flock -n 200
then
    if [ -n "$ARG" ]
    then
        echo "DLRN ${USER} running, please try again after disabling it."
    fi
    exit 1
fi

if [ ! -d /home/${USER}/dlrn-logs ]
then
    mkdir -p /home/${USER}/dlrn-logs
fi

source ~/.venv/bin/activate
if [ -n "$ARG" ]
then
    LOGFILE=/home/${USER}/dlrn-logs/dlrn-run.console.$(date +%s).log
else
    LOGFILE=/home/${USER}/dlrn-logs/dlrn-run.$(date +%s).log
fi
cd ~/dlrn

set +e
echo `date` "Starting DLRN run." >> $LOGFILE
dlrn --config-file /usr/local/share/dlrn/${USER}/projects.ini --info-repo /home/rdoinfo/rdoinfo/ ${DLRN_ENV:-} "$@" 2>> $LOGFILE
RET=$?
echo `date` "DLRN run complete." >> $LOGFILE

if [ -n "$ARG" ]
then
    echo Arguments: "$@"
    cat $LOGFILE
fi
exit $RET
