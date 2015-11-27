# puppet-delorean

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with puppet-delorean](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Overview
This is a Puppet module aimed at setting up a new Delorean instance from
scratch.

## Module Description

[Delorean](https://github.com/openstack-packages/delorean) builds and maintains yum repositories following OpenStack uptream commit streams. 

The Delorean infrastructure on an instance contains the following components:

- A number of `workers`. A worker is basically a local user, with a local Delorean checkout from the GitHub repo, and some associated configuration.

- An `rdoinfo` user. This user simply hosts a local checkout of the [rdoinfo repository](https://github.com/redhat-openstack/rdoinfo), which is refreshed periodically using a crontab entry.

- A web server to host the generated repos.

You can find more information on the Delorean instance architecture [here](https://github.com/redhat-openstack/delorean-instance/blob/master/docs/delorean-instance.md).

This module can configure the basic parameters required by a Delorean instace, plus all the workers.

## Setup

- yum -y install puppet augeas
- git clone https://github.com/javierpena/puppet-delorean
- cd puppet-delorean
- puppet module build
- puppet module install pkg/jpena-delorean-*.tar.gz

## Usage

Once the puppet-delorean module is installed, the simplest Puppet manifest that creates a Delorean environment for you is:

    class { 'delorean': }

This is a simplistic manifest, that sets everything based on default values. Specifically, the following parts will be disabled:

- The lsyncd configuration.
- E-mail notifications when package builds fail.
- The cron jobs used to trigger periodic Delorean runs.

Once you have been able to check that everything is configured as expected, you can use the following manifest to set the Delorean instance in "production mode":

    class { 'delorean': 
      backup_server          => 'testbackup.example.com',
      sshd_port              => 3300,
      disable_email          => false,
      enable_worker_cronjobs => true,
    }

## Reference

TODO: include all the classes and defines here

## Limitations

For now, the module has only been tested under Fedora.

