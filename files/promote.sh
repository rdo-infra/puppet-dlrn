#!/bin/bash -xe
function local_promote() {
    # Promotes a symlink locally

    # Verify uniqueness
    count="$(find . -maxdepth 3 -mindepth 3 -type d -name \*${hash}\* | wc -l)"
    if [ "${count}" != "1" ]; then
        echo "Uniqueness must be enforced!"
        exit 1
    fi

    ln -nsvf */*/*${hash}* ${linkname}
    echo "${hash}" >> promote-${linkname}.log
}

function remote_promote() {
    # Promotes a symlink remotely, if possible
    config="/usr/local/share/dlrn/${instance}/projects.ini"

    # Validate that the required configuration is available
    [[ ! -f "${config}" ]] && return 0
    grep -q "rsyncdest" "${config}" || return 0
    grep -q "rsyncport" "${config}" || return 0

    rsyncdest=$(grep "rsyncdest" "${config}" |cut -f2 -d =)
    rsyncport=$(grep "rsyncport" "${config}" |cut -f2 -d =)

    rsync -av -e "ssh -p ${port}" "${linkname}" "${rsyncdest}"
    rsync -av -e "ssh -p ${port}" "promote-${linkname}.log" "${rsyncdest}"
}

# Ensure we don't allow any special characters into the script
for ARG in $@ ; do
    if [[ ! $ARG =~ ^[a-zA-Z0-9_-]+$ ]] ; then
        echo "Invalid parameter format : $ARG"
        exit 1
    fi
done

hash="${1}"
if [ -z "${hash}" ]; then
    echo "Please give me a hash to point at!"
    exit 1
fi

instance="${2}"
if [ -z "${instance}" ]; then
    echo "Please specify the DLRN instance to use!"
    exit 1
fi

linkname="${3:-current-passed-ci}"

pushd /home/${instance}/data/repos
local_promote
remote_promote
popd
