#!/bin/bash -xe

# Ensure we don't allow any special characters into the script
for ARG in $@ ; do
    if [[ ! $ARG =~ ^[a-zA-Z0-9_-]+$ ]] ; then
        echo "Invalid parameter format : $ARG"
        exit 1
    fi
done

if [ -z "$1" ]; then
    echo "Please give me a hash to point at!"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please specify the DLRN instance to use!"
    exit 1
fi

LINKNAME=${3:-current-passed-ci}

cd /home/${2}/data/repos

# Create full path for repo directory
repo="$(echo ${1}| cut -c 1-2)/$(echo ${1}| cut -c 3-4)/${1}"
# Check that the repo directory actually exists
if [ ! -d $repo ]; then
    echo "Hash repo does not exist!"
    exit 1
fi

ln -nsvf $repo $LINKNAME
echo "$1" >> promote-${LINKNAME}.log
