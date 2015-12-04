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

    $ yum -y install puppet augeas
    $ git clone https://github.com/javierpena/puppet-delorean
    $ cd puppet-delorean
    $ puppet module build
    $ puppet module install pkg/jpena-delorean-*.tar.gz

## Usage

Once the puppet-delorean module is installed, the simplest Puppet manifest that creates a Delorean environment for you is:

```puppet
class { 'delorean': }
```

This is a simplistic manifest, that sets everything based on default values. Specifically, the following parts will be disabled:

- The lsyncd configuration.
- E-mail notifications when package builds fail.
- The cron jobs used to trigger periodic Delorean runs.

Once you have been able to check that everything is configured as expected, you can use the following manifest to set the Delorean instance in "production mode":

```puppet
class { 'delorean': 
  backup_server          => 'testbackup.example.com',
  sshd_port              => 3300,
  disable_email          => false,
  enable_worker_cronjobs => true,
}
```

## Reference

### Class: delorean

This is the higher level class, that will configure a Delorean instance.

```puppet
class { 'delorean':
  sshd_port              = 1234,
  disable_email          = true,
  enable_worker_cronjobs = false,
  backup_server          = undef,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to. This is useful when you need to access your Delorean instance over the Internet, to reduce the amount of automated attacks against sshd.

####`disable_email`
Disable e-mails when a package build fails. Set this to true until the worker runs are stable, to avoid spamming package maintainers with spurious failure e-mails.

####`enable_worker_cronjobs`
Enable cron jobs for Delorean workers. By default it is set to false, to give you some time to check that the configuration is correct. Set it to true to enable normal operations.

####`backup_server`
The Delorean instance architecture includes a secondary server, where all repos are synchronized using lsyncd. If this variable is set, the required lsyncd configuration will be created to enable this synchronization. Be aware that you will need to configure passwordless SSH access to root@backup_server for this to work.

### Class: delorean::fail2ban

This class is used internally, and configures fail2ban for Delorean.

```puppet
class { 'delorean::fail2ban' :
  sshd_port = 1234,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to.

### Class: delorean::promoter

This class is used internally, to set up a promoter user for Delorean. This user is dedicated to promoting repositories that pass CI tests.

```puppet
class { 'delorean::promoter' : }
```

### Class: delorean::rdoinfo

This class is used internally, to set up an rdoinfo user for Delorean. This user is dedicated to synchronizing the contents of [rdoinfo](https://github.com/redhat-openstack/rdoinfo).

```puppet
class { 'delorean::rdoinfo' : }
```

### Class: delorean::web

This class is used internally, to set up the Apache instance for Delorean and fetch the static content.

```puppet
class { 'delorean::web' : }
```

### Define delorean::lsyncdconfig

This defined resource type is used to create the configuration fragments for file /etc/lsyncd.conf.

```puppet
delorean::lsyncdconfig { 'lsync-user':
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

### Define delorean:worker

This defined resource type creates all required configuration for a Delorean worker. It is used internally by class delorean, but it may also be used externally from the site manifest to create additional workers.

```puppet
delorean::worker { 'fedora-master':
  distro         => 'f22',
  target         => 'fedora',
  distgit_branch => 'rpm-master',
  distro_branch  => 'master',
  disable_email  => true,
  enable_cron    => false,
  symlinks       => ['/var/www/html/f22',
                      '/var/www/html/f21',
                      '/var/www/html/fedora22',
                      '/var/www/html/fedora21'],
}
```

####`distro`
The distribution used to create Delorean packages. Currently used values are `centos7`, `f22` and `f24`

####`target`
Specifies the mock target used by Delorean. The basic mock targets are `centos` and `fedora`, but there are specific code paths that create mock targets for others: `centos-kilo`, `centos-liberty`, and `fedora-master-rawhide`.

####`distgit_branch`
Specifies the branch for the dist-git: `rpm-master` for trunk packages, `rpm-liberty` for stable/liberty, `rpm-kilo` for stable/kilo.

####`distro_branch`
Specifies the branch for upstream git: `master`, `stable/liberty`, etc.

####`disable_email`
Disable e-mails when a package build fails.

####`enable_cron`
Enable the cron jobs for this Delorean worker.

####`symlinks`
This is a list that specifies a set of symbolic links that will be created, pointing to `/home/$user/data/repos`.

## Limitations

For now, the module has only been tested under Fedora.

