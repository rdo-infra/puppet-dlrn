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

[DLRN](https://github.com/softwarefactory-project/DLRN) builds and maintains yum repositories following OpenStack uptream commit streams.

The DLRN infrastructure on an instance contains the following components:

- A number of `workers`. A worker is basically a local user, with a local DLRN checkout from the GitHub repo, and some associated configuration.
- An `rdoinfo` user. This user simply hosts a local checkout of the [rdoinfo repository](https://github.com/redhat-openstack/rdoinfo), which is refreshed periodically using a crontab entry.
- A web server to host the generated repos.

You can find more information on the DLRN instance architecture [here](https://github.com/redhat-openstack/delorean-instance/blob/master/docs/delorean-instance.md).

This module can configure the basic parameters required by a DLRN instace, plus all the workers.

## Setup

    $ yum -y install puppet
    $ git clone https://github.com/rdo-infra/puppet-dlrn
    $ cd puppet-dlrn
    $ puppet module build
    $ puppet module install pkg/jpena-dlrn-*.tar.gz

### Setup on puppet 6:

    sudo dnf install -y https://yum.puppet.com/puppet6-release-el-8.noarch.rpm

Build module:

    sudo dnf install -y https://yum.puppet.com/puppet-tools-release-el-8.noarch.rpm
    sudo dnf install -y pdk
    git clone https://github.com/javierpena/puppet-dlrn
    cd puppet-dlrn
    pdk build --force
    puppet module install pkg/jpena-dlrn-0.1.0.tar.gz

Sample site.pp file:

    cp puppet-dlrn/examples/site.pp /etc/puppetlabs/code/environments/production/manifests/

Copy example of hieradata params:

    cp ~/puppet-dlrn/examples/common.yaml /etc/puppetlabs/code/environments/production/data/

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
  server_type       => 'primary',
  enable_https      => false
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to. This is useful when you need to access your DLRN instance over the Internet, to reduce the amount of automated attacks against sshd.

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
}
```

####`sshd_port`
Specifies the alternate port sshd will use to listen to.

####`enable_https`
Enable ssl in apache configuration. Certificates are managed using Let's Encrypt service. Defaults to false.

####`disk_for_builders`
If set, it will use the specified disk to create a volume group called vgdelorean and mount it as /home, so all builders will be stored there. Defaults to `undef`.

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

####`enable_api`
Enable the DLRN API. This is done by creating a WSGI process under apache, and each enabled worker will get its own URL. Defaults to false.

####`api_workers`
If `enable_api` is true, this array will define which workers will be added to the vhost configuration as WSGI. Each worker will have a url of /api-${worker} associated to its WSGI script.

### Define dlrn:worker

This defined resource type creates all required configuration for a DLRN worker. It is used internally by class dlrn, but it may also be used externally from the site manifest to create additional workers.

```puppet
dlrn::worker { 'centos-master':
  distro         => 'centos8',
  target         => 'centos',
  distgit_branch => 'rpm-master',
  distro_branch  => 'master',
  disable_email  => true,
  enable_cron    => false,
  symlinks       => ['/var/www/html/c8',
                      '/var/www/html/centos8'],
  release        => 'train',
}
```

####`distro`
The distribution used to create DLRN packages. Currently used values are `centos7 and centos8.

####`target`
Specifies the mock target used by DLRN. The basic mock targets are `centos` and `fedora`, but there are specific code paths that create mock targets for others: `centos-train` and `centos-stein`.

####`distgit_branch`
Specifies the branch for the dist-git: `rpm-master` for trunk packages, `stein-rdo` for stable/stein, `train-rdo` for stable/train.

####`distro_branch`
Specifies the branch for upstream git: `master`, `stable/train`, etc.

####`uid`
Specifies the UID to use for the worker user. Defaults to `undef`, which means "let the operating system choose automatically".

####`disable_email`
Disable e-mails when a package build fails.

####`mock_tmpfs_enable`
Enable the mock tmpfs plugin. Note this requires a lot of RAM (up to 4 GB per worker). Defaults to `false`.

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
This is the release name this worker will be targetting, in lower case. For example, 'stein' or 'train'.

####`baseurl`
This is the base URL for the exported repositories. It will be used as part of the generated .repo file. For example, 'https://trunk.rdoproject.org/centos7-stein'

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

####`fallback_to_master`
This parameter defines the fallback behavior when a selected branch is not available in the Git repo. If set to `true`, DLRN will fall back to the master branch
for source repositories if the configured branch cannot be found, and rpm-master for distgit repositories. Defaults to `true`.

####`include_srpm_in_repo`
If set to `false`, DLRN will exclude source RPMs from the generated repositories. Defaults to `true`, which means source RPMs are included.

####`nonfallback_branches`
This parameter defines a list of regular expressions of branches for source and distgit repositories that should never fall back to other branches, even if not present in the repository.
Defaults to `'^master$,^rpm-master$'`.

####`worker_processes`
This parameter defines the number of worker processes to use during build. Defaults to `1`.

####`use_components`
If set to `true`, this parameter will tell DLRN to use a component-based structure for its repositories. Defaults to `false`.

####`pkginfo_driver`
This is the DLRN driver used to manage the distgit repositories. The current available options are 'dlrn.drivers.rdoinfo.RdoInfoDriver', 'dlrn.drivers.gitrepo.GitRepoDriver' and 'dlrn.drivers.downstream.DownstreamInfoDriver'. Defaults to `'dlrn.drivers.rdoinfo.RdoInfoDriver'`

####`build_driver`
This is the DLRN driver used to build packages. The current available options are 'dlrn.drivers.mockdriver.MockBuildDriver', 'dlrn.drivers.kojidriver.KojiBuildDriver' and 'dlrn.drivers.coprdriver.CoprBuildDriver'. Defaults to `'dlrn.drivers.mockdriver.MockBuildDriver'`.

####`gitrepo_repo`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is the Git repo to use as a source. Defaults to `http://github.com/openstack/rpm-packaging`

####`gitrepo_dir`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is the directory inside gitrepo_repo wherethe spec files area located. Defaults to `/openstack`

####`gitrepo_skip`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option must be specified, and it is a list of directories inside gitrepo_dir to be skipped by the gitrepo driver, when finding packages to be built. Defaults to `['openstack-macros']`

####`gitrepo_use_version_from_spec`
If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this option specifies whether the gitrepo driver will parse the spec file and use the version from it as source-branch or not. Defaults to `true`.

####`downstream_distroinfo_repo`
If pkginfo_driver is  'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the distroinfo repository to get package information from. Defaults to `undef`.

####`downstream_info_files`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the info file (or a list of info files) to get package information from, within the distroinfo repo. Defaults to `undef`.

####`downstream_versions_url`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the URL of a versions.csv file generated by another DLRN instance. distro_hash and commit_hash will be reused from supplied versions.csv and only packages present in the file are processed. Defaults to `undef`.

####`downstream_distro_branch`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the  branch to use when cloning the downstream distgit, since it may be different from the upstream distgit branch. Defaults to `undef`.

####`downstream_tag`
If pkginfo_driver is'dlrn.drivers.downstream.DownstreamInfoDriver', this option will filter the 'packages' section of packaging metadata (from 'repo/info_files') to only contain packages with the 'downstream_tag' tag. This tag will be filtered in addition to the one set in the 'DEFAULT/tags' section. Defaults to `undef`.

####`downstream_distgit_key`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option will specify the key used to find the downstream distgit in the 'packages' section of packaging metadata (from 'repo/info_files'). Defaults to `undef`.

###`use_upstream_spec`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option defines if the upstream distgit contents (spec file and additional files) should be copied  over the downstream distgit after cloning. Defaults to `false`.

###`downstream_spec_replace_list`
If pkginfo_driver is 'dlrn.drivers.downstream.DownstreamInfoDriver', this option will perform some#   sed-like edits in the spec file after copying it from the upstream to the downstream distgit. This is specially useful when the downstream DLRN instance has special requirements, such as building without documentation. For example:

```
    downstream_spec_replace_list=^%global with_doc.+/%global with_doc 0
```

Multiple regular expressions can be used, separated by commas.

Defaults to `undef`.

####`koji_exe`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this option defines the executable to use. Some Koji instances create their own client packages to add their default configuration, such as CBS or Brew. Defaults to `'koji'`

####`koji_krb_principal`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this option defines the Kerberos principal to use for the Koji builds. If it is set to undef, DLRN will assume that authentication is performed using SSL certificates. Defaults to `undef`.

####`koji_krb_keytab`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this is the full path to a Kerberos keytab file, which contains the Kerberos credentials for the principal defined in the koji_krb_principal option. Defaults to `undef`.

####`koji_scratch_builds`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this option defines if a scratch build should be used. Defaults to `true`.

####`koji_build_target`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this option defines the build target to use. This defines the buildroot and base repositories to be used for the build. Defaults to `undef`.

####`koji_arch`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', this option defines an override to the default architecture (x86_64) in some cases (e.g retrieving mock configuration from Koji instance).  Defaults to `x86_64`.

####`koji_fetch_mock_config`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', when this option is set to true, DLRN will download the mock configuration for the build target from Koji, and use it when building the source RPM.  If set to 'false', DLRN will use its internally defined mock configuration, based on the ``DEFAULT/target`` configuration option. Defaults to `false`.

####`koji_use_rhpkg`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver', when this option is set to true, `rhpkg` will be used by DLRN as the build tool in combination with `koji_exe`. Defaults to `false`.

####`koji_mock_base_packages`
If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver' and ``fetch_mock_config`` is set to ``true``, this option will define the set of base packages that will be installed in the mock configuration when creating the source RPM. This list of packages will override the one fetched in the mock configuration, if set. If not set, no overriding will be done.

####`enable_deps_sync`
When set to true a cron job is created to synchronize dependencies from CBS into $HOME/data/repos/deps/latest in primary server.

####`enable_brs_sync`
When set to true a cron job is created to synchronize build dependencies from CBS into $HOME/data/repos/build-deps/latest in primary server.


## Limitations

The module has been tested on Fedora and CentOS.

**Important note about letsencrypt module:**This module requires puppet module letsencrypt > 1.0.0 (commit 3c5d17697f14a32f51b24d11f5c6a164d43c1a54 is required). At the time of writing this version of puppet-dlrn, latest version in puppetforge is 1.0.0 so until it's updated in puppetforge it must be cloned from  https://github.com/danzilio/puppet-letsencrypt.

## Contributing

The project is now using the Gerrit infrastructure at https://review.rdoproject.org, so please submit reviews there.
