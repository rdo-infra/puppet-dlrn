#!/bin/bash
# This script iterates across the dlrn instances, retrieves their
# symlinks, their targets, and synchronizes them on a remote instance

destination="trunk.rdoproject.org"
port="3300"
instances="centos-master centos-mitaka centos-liberty fedora-master fedora-rawhide-master"

for instance in $instances; do
    links=$(find /home/${instance}/data/repos/ -maxdepth 1 -type l)
    for link in $links; do
        # Run the synchronization and send the log output to journal
        systemd-cat -t ${0} sudo -u ${instance} rsync -av -e "ssh -p ${port}" ${link} ${instance}@${destination}:/home/${instance}/data/repos/
    done
done
