# puppet-dlrn

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with puppet-dlrn](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Overview
This is a Puppet module aimed at setting up a new DLRN instance from
scratch.

## Module Description

[DLRN](https://github.com/openstack-packages/DLRN) builds and maintains yum repositories following OpenStack uptream commit streams. 

The DLRN infrastructure on an instance contains the following components:

- A number of `workers`. A worker is basically a local user, with a local DLRN checkout from the GitHub repo, and some associated configuration.
- An `rdoinfo` user. This user simply hosts a local checkout of the [rdoinfo repository](https://github.com/redhat-openstack/rdoinfo), which is refreshed periodically using a crontab entry.
- A web server to host the generated repos.

You can find more information on the DLRN instance architecture [here](https://github.com/redhat-openstack/delorean-instance/blob/master/docs/delorean-instance.md).

This module can configure the basic parameters required by a DLRN instace, plus all the workers.

## Setup

    $ yum -y install puppet
    $ git clone https://github.com/javierpena/puppet-dlrn
    $ cd puppet-dlrn
    $ puppet module build
    $ puppet module install pkg/jpena-dlrn-*.tar.gz

## Usage

Once the puppet-dlrn module is installed, you will need to create a suitable Hiera file to define the workers. You have an example file at `examples/common.yaml`. Just place it at `/var/lib/hiera/common.yaml`, and it will create the same configuration that is currently being used at the production DLRN environment. If you need a different set of workers, just modify the file accordingly to suit your needs.

The simplest Puppet manifest that creates a DLRN environment for you is:

```puppet
class { 'dlrn': }
```

This is a simplistic manifest, that sets everything based on default values. Specifically, the following parts will be disabled:

- The lsyncd configuration.
- E-mail notifications when package builds fail.
- The cron jobs used to trigger periodic DLRN runs.

Once you have been able to check that everything is configured as expected, you need to do two things to set the DLRN instance in "production mode":

- Set `enable_worker_cronjobs: &enable_cron true` and `disable_worker_email: &disable_email false` in /`var/lib/hiera/common.yaml`.
- Change the Puppet manifest to look like the following:

```puppet
class { 'dlrn':
  backup_server          => 'testbackup.example.com',
  sshd_port              => 3300,
}
```

## Reference

### Class: dlrn

This is the higher level class, that will configure a DLRN instance.

```puppet
class { 'dlrn':
  sshd_port              => 1234,
  backup_server          => undef,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to. This is useful when you need to access your DLRN instance over the Internet, to reduce the amount of automated attacks against sshd.

####`backup_server`
The DLRN instance architecture includes a secondary server, where all repos are synchronized using lsyncd. If this variable is set, the required lsyncd configuration will be created to enable this synchronization. Be aware that you will need to configure passwordless SSH access to root@backup_server for this to work.

### Class: dlrn::common

This class is used internally, to configure the common OS-specific aspects required by DLRN.

```puppet
class { 'dlrn::common':
  sshd_port              => 1234,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to.

### Class: dlrn::fail2ban

This class is used internally, and configures fail2ban for DLRN.

```puppet
class { 'dlrn::fail2ban' :
  sshd_port => 1234,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to.

### Class: dlrn::promoter

This class is used internally, to set up a promoter user for DLRN. This user is dedicated to promoting repositories that pass CI tests.

```puppet
class { 'dlrn::promoter' : }
```

### Class: dlrn::rdoinfo

This class is used internally, to set up an rdoinfo user for DLRN. This user is dedicated to synchronizing the contents of [rdoinfo](https://github.com/redhat-openstack/rdoinfo).

```puppet
class { 'dlrn::rdoinfo' : }
```

### Class: dlrn::web

This class is used internally, to set up the Apache instance for DLRN and fetch the static content.

```puppet
class { 'dlrn::web' : }
```

### Define dlrn::lsyncdconfig

This defined resource type is used to create the configuration fragments for file /etc/lsyncd.conf.

```puppet
dlrn::lsyncdconfig { 'lsync-user':
  path         => '/home/user',
  sshd_port    => 1234,
  remoteserver => 'backupserver.example.com',
}
```

####`path`
Specifies the path to synchronize. The target path will be the same as the source path.

####`sshd_port`
Specifies the alternate port sshd is listening to.

####`remoteserver`
Specifies the backup server.  Be aware that you will need to configure passwordless SSH access to root@backup_server for this to work.

### Define dlrn:worker

This defined resource type creates all required configuration for a DLRN worker. It is used internally by class dlrn, but it may also be used externally from the site manifest to create additional workers.

```puppet
dlrn::worker { 'fedora-master':
  distro         => 'f23',
  target         => 'fedora',
  distgit_branch => 'rpm-master',
  distro_branch  => 'master',
  disable_email  => true,
  enable_cron    => false,
  symlinks       => ['/var/www/html/f23',
                      '/var/www/html/f22',
                      '/var/www/html/fedora23',
                      '/var/www/html/fedora22'],
  release        => 'mitaka',
}
```

####`distro`
The distribution used to create DLRN packages. Currently used values are `centos7`, `f23` and `f24`

####`target`
Specifies the mock target used by DLRN. The basic mock targets are `centos` and `fedora`, but there are specific code paths that create mock targets for others: `centos-kilo`, `centos-liberty`, 'centos-mitaka' and `fedora-master-rawhide`.

####`distgit_branch`
Specifies the branch for the dist-git: `rpm-master` for trunk packages, `rpm-liberty` for stable/liberty, `rpm-kilo` for stable/kilo.

####`distro_branch`
Specifies the branch for upstream git: `master`, `stable/liberty`, etc.

####`uid`
Specifies the UID to use for the worker user. Defaults ti `undef`, which means "let the operating system choose automatically".

####`disable_email`
Disable e-mails when a package build fails.

####`enable_cron`
Enable the cron jobs for this DLRN worker.

####`symlinks`
This is a list that specifies a set of symbolic links that will be created, pointing to `/home/$user/data/repos`.

####`release`
This is the release name this worker will be targetting, in lower case. For example, 'mitaka' or 'liberty'.

####`gerrit_user` 
This is a user to run Gerrit reviews for packages after build failures. If set to undef (default), Gerrit reviews are disabled for this worker.

####`gerrit_email` 
This is the email for the user to run Gerrit reviews for packages after build failures. It is required when `gerrit_user` is set, and ignored otherwise.

###`rsyncdest`
This is the destination where builtdir and reports are replicated when build is ok in scp-like format. Defaults to `undef`, which means that replication is disabled.

###`rsyncport`
This is the port number for ssh in server where builtdir and reports are replicated. Defaults to `22`.

## Limitations

The module has been tested on Fedora and CentOS.

