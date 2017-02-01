# puppet-dlrn

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with puppet-dlrn](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Contributing](#contributing)

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

- E-mail notifications when package builds fail.
- The cron jobs used to trigger periodic DLRN runs.

Once you have been able to check that everything is configured as expected, you need to do two things to set the DLRN instance in "production mode":

- Set `enable_worker_cronjobs: &enable_cron true` and `disable_worker_email: &disable_email false` in /`var/lib/hiera/common.yaml`.
- Change the Puppet manifest to look like the following:

```puppet
class { 'dlrn':
  sshd_port              => 3300,
}
```

## Reference

### Class: dlrn

This is the higher level class, that will configure a DLRN instance.

```puppet
class { 'dlrn':
  sshd_port         => 1234,
  mock_tmpfs_enable => false,
  server_type       => 'primary',
  enable_https      => false
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to. This is useful when you need to access your DLRN instance over the Internet, to reduce the amount of automated attacks against sshd.

####`mock_tmpfs_enable`
Enables the Mock TMPfs plugin. Note this will enable creation of a file system in RAM using up to 6 GB per worker, so be sure you have enough RAM and swap for all workers.

####`server_type`
Defines the server_type. It can be set to primary (default) or passive. Even when enabled in workers hiera configuration, passive servers will not enable:
- cron jobs for run-dlrn.sh
- rsync of new builds (they are suposed to be the destination of the synchronization)
- Opening reviews in gerrit automatically on FTBFS
- Sending mails on build failure
Additionally, passive servers will redirect to buildlogs when users trying to access to current-passed-ci or current-tripleo

####`enable_https`
Enable ssl in apache configuration. Certificates are managed using Let's Encrypt service. Defaults to false.


### Class: dlrn::common

This class is used internally, to configure the common OS-specific aspects required by DLRN.

```puppet
class { 'dlrn::common':
  sshd_port         => 1234,
  mock_tmpfs_enable => false,
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to.

####`mock_tmpfs_enable`
Enables the Mock TMPfs plugin. Note this will enable creation of a file system in RAM using up to 6 GB per worker, so be sure you have enough RAM and swap for all workers.

####`enable_https`
Enable ssl in apache configuration. Certificates are managed using Let's Encrypt service. Defaults to false.

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

####`web_domain`
Specifies the domain name used for the web server running in dlrn server.

####`enable_https`
Enable ssl in apache configuration. Certificates are managed using Let's Encrypt service. Defaults to false.

####`cert_mail`
The email address to use to register with Let's Encrypt. Required if enable_https is set to true.


### Define dlrn:worker

This defined resource type creates all required configuration for a DLRN worker. It is used internally by class dlrn, but it may also be used externally from the site manifest to create additional workers.

```puppet
dlrn::worker { 'fedora-master':
  distro         => 'f24',
  target         => 'fedora',
  distgit_branch => 'rpm-master',
  distro_branch  => 'master',
  disable_email  => true,
  enable_cron    => false,
  symlinks       => ['/var/www/html/f24',
                      '/var/www/html/fedora24'],
  release        => 'newton',
}
```

####`distro`
The distribution used to create DLRN packages. Currently used values are `centos7`, `f24` and `f25`

####`target`
Specifies the mock target used by DLRN. The basic mock targets are `centos` and `fedora`, but there are specific code paths that create mock targets for others: `centos-newton`, 'centos-mitaka' and `fedora-master-rawhide`.

####`distgit_branch`
Specifies the branch for the dist-git: `rpm-master` for trunk packages, `newton-rdo` for stable/newton, `rpm-mitaka` for stable/mitaka.

####`distro_branch`
Specifies the branch for upstream git: `master`, `stable/newton`, etc.

####`uid`
Specifies the UID to use for the worker user. Defaults ti `undef`, which means "let the operating system choose automatically".

####`disable_email`
Disable e-mails when a package build fails.

####`enable_cron`
Enable the cron jobs for this DLRN worker.

####`cron_env`
If enable_cron is true, we can add parameters to the run-dlrn.sh execution using this string. It will be used as an environment variable when running the script.

####`cron_hour`
If enable_cron is true, set the hour for the cron job

####`cron_minute`
If enable_cron is true, set the minute for the cron job

####`enable_purge`
Enable a cron job to periodically purge old commits from the DLRN db and file system, reducing space requirements. Defaults to false.

####`purge_hour`
If enable_purge is true, set the hour for the cron job. Defaults to '1'.

####`purge_minute`
If enable_purge=true, set the minute for the cron job. Defaults to '7'.

####`symlinks`
This is a list that specifies a set of symbolic links that will be created, pointing to `/home/$user/data/repos`.

####`release`
This is the release name this worker will be targetting, in lower case. For example, 'mitaka' or 'newton'.

####`baseurl`
This is the base URL for the exported repositories. It will be used as part of the generated .repo file. For example, 'https://trunk.rdoproject.org/centos7-mitaka'

####`gerrit_user`
This is a user to run Gerrit reviews for packages after build failures. If set to undef (default), Gerrit reviews are disabled for this worker.

####`gerrit_email`
This is the email for the user to run Gerrit reviews for packages after build failures. It is required when `gerrit_user` is set, and ignored otherwise.

####`gerrit_topic`
This is the Gerrit topic to use when opening a review for packages after build failures. It is ignored if `gerrit_user` is not set.

####`rsyncdest`
This is the destination where builtdir and reports are replicated when build is ok in scp-like format. Defaults to `undef`, which means that replication is disabled.

####`rsyncport`
This is the port number for ssh in server where builtdir and reports are replicated. Defaults to `22`.

####`server_type`
This defines if the server where the worker is being configured is primary or passive (see explanation in Class: dlrn section). Defaults to the value defined

####`db_connection`
This parameter defines a database connection string to be used by DLRN, in the SQLAlchemy syntax. Defaults to 'sqlite://commits.sqlite', which is a local SQLite3 database.

####`enable_api`
Enable the DLRN API. This is done by creating a WSGI process under apache, and each worker will use one port for API communication. Defaults to false.

####`api_port`
If `enable_api` is set to true, use this port in Apache for the DLRN API communications to this worker.

####`worker_processes`
This parameter defines the number of worker processes to use during build. Defaults to `1`.

####`pkginfo_driver`
This is the DLRN driver used to manage the distgit repositories. The current available options are 'dlrn.drivers.rdoinfo.RdoInfoDriver' and 'dlrn.drivers.gitrepo.GitRepoDriver'. Defaults to `'dlrn.drivers.rdoinfo.RdoInfoDriver'`

####`gitrepo_repo`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is the Git repo to use as a source. Defaults to `http://github.com/openstack/rpm-packaging`

####`gitrepo_dir`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is the directory inside gitrepo_repo wherethe spec files area located. Defaults to `/openstack`

####`gitrepo_skip`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is a list of directories inside gitrepo_dir to be skipped by the gitrepo driver, when finding packages to be built. Defaults to `['openstack-macros']`

####`gitrepo_use_version_from_spec`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option specifies whether the gitrepo driver will parse the spec file and use the version from it as source-branch or not. Defaults to `true`.


## Limitations

The module has been tested on Fedora and CentOS.

**Important note about letsencrypt module:**This module requires puppet module letsencrypt > 1.0.0 (commit 3c5d17697f14a32f51b24d11f5c6a164d43c1a54 is required). At the time of writing this version of puppet-dlrn, latest version in puppetforge is 1.0.0 so until it's updated in puppetforge it must be cloned from  https://github.com/danzilio/puppet-letsencrypt.

## Contributing

The project is now using the Gerrit infrastructure at https://review.rdoproject.org, so please submit reviews there.
