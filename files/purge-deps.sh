#!/bin/bash
#   Copyright Red Hat, Inc. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
#

DIRS="/home/${USER}/data/repos/deps /home/${USER}/data/repos/build-deps"
LOGFILE=/home/${USER}/dlrn-logs/purge-deps.$(date +%s).log
RETENTION=30

if [ ! -d /home/${USER}/dlrn-logs]; then
    mkdir /home/${USER}/dlrn-logs
fi

for directory in $DIRS; do
    if [ -d $directory ]; then
        find $directory -mindepth 1 -maxdepth 1 -type d -mtime +${RETENTION} |grep -v latest | while read line; do
            echo "Removing $line" >> $LOGFILE
            rm -r $line
        done
    fi
done
