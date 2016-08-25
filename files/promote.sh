#!/bin/bash -xe
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

cd /home/${instance}/data/repos

# Verify uniqueness
count="$(find . -maxdepth 3 -mindepth 3 -type d -name \*${hash}\* | wc -l)"
if [ "${count}" != "1" ]; then
    echo "Uniqueness must be enforced!"
    exit 1
fi

# Promote symlink locally
ln -nsvf */*/*${hash}* ${linkname}
echo "${hash}" >> promote-${linkname}.log
