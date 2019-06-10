# == Class: dlrn::worker
#
#  This class sets up a DLRN worker
#
# === Parameters:
#
# [*distro*]
#   (required) Distro for worker (f24, centos7...)
#
# [*target*]
#   (required) Mock target (fedora, centos, fedora-rawhide, centos-rocky...)
#
# [*distgit_branch*]
#   (optional) Branch for dist-git
#   Defaults to rpm-master
#
# [*distro_branch*]
#   (optional) Branch for upstream git
#   Defaults to master
#
# [*uid*]
#   (optional) uid for user
#   Defaults to undef
#
# [*disable_email*]
#   (optional) Disable e-mail notifications
#   Defaults to true
#
# [*mock_tmpfs_enable*]
#   (optional) Enable the mock tmpfs plugin. This can override the option set
#              in class dlrn. Note this requires a lot of RAM
#   Defaults to false
#
# [*enable_cron*]
#   (optional) Enable cron jobs to run DLRN on the worker every 5 minutes
#   Defaults to false
#
# [*cron_env*]
#   (optional) Environment variables for DLRN cron command (run-dlrn.sh)
#   Defaults to empty string
#
# [*cron_hour*]
#   (optional) If enable_cron=true, set the hour for the cron job
#   Defaults to '*'
#
# [*cron_minute*]
#   (optional) If enable_cron=true, set the minute for the cron job
#   Defaults to '*/5' (every 5 minutes)
#
# [*enable_purge*]
#   (optional) Enable a cron job to periodically purge old commits from the
#   DLRN db and file system, reducing space requirements.
#   Defaults to false
#
# [*purge_hour*]
#   (optional) If enable_purge=true, set the hour for the cron job
#   Defaults to '1'
#
# [*purge_minute*]
#   (optional) If enable_purge=true, set the minute for the cron job
#   Defaults to '7'
#
# [*symlinks*]
#   (optional) List of directories to be symlinked under to the repo directory
#   Example: ['/var/www/html/f24','/var/www/html/fedora24']
#   Defaults to undef
#
# [*release*]
#   (optional) Release this worker will be using (all lowercase)
#   Example: 'ocata'
#   Defaults to 'rocky'
#
# [*baseurl*]
#   (optional) Base URL for the exported repositories
#   Example: 'https://trunk.rdoproject.org/centos7-ocata'
#   Defaults to 'http://localhost'
#
# [*gerrit_user*]
#   (optional) User to run Gerrit reviews after build failures. If set to undef,
#     do not enable Gerrit reviews
#   Example: 'rdo-trunk'
#   Defaults to undef
#
# [*gerrit_email*]
#   (optional) E-mail for gerrit_user.
#   Example: 'rdo-trunk@rdoproject.org'
#   Defaults to undef
#
# [*gerrit_topic*]
#   (optional) Gerrit topic to use when opening a review. Only used it gerrit_user
#   is set
#   Example: 'rdo-FTBFS-ocata'
#   Defaults to 'rdo-FTBFS'
#
# [*rsyncdest*]
#   (optional) destination where builtdir and reports are replicated when build is ok.
#     format: <user>@<ip or hostname>:<destdir>
#   Example: 'centos-master@backupserver.example.com:/home/centos-master/data/repos'
#   Defaults to undef
#
# [*rsyncport*]
#   (optional) port number for ssh in server where builtdir and reports are copied
#     after built is successfull.
#   Example: '22'
#   Defaults to '22'
#
# [*enable_public_rsync*]
#   (optional) Enable a public rsyncd module for the worker repos.
#   Defaults to false
#
# [*public_rsync_hosts_allow*]
#   (optional) if enable_public_rsync is true, this variable defines a list of
#   hosts/networks which will be allowed to sync from this module.
#   Defaults to undef (meaning everyone can sync).
#
# [*worker_processes*]
#   (optional) Number of worker processes to use during build.
#   Defaults to 1
#
# [*use_components*]
#   (optional) If set to true, tell DLRN to use a component-based structure for
#   its repositories
#   Defaults to false
#
# [*server_type*]
#   (optional) server_type can be set to primary or passive. Primary server
#   check periodically for changes in repos and synchronize every build to a
#   passive server if rsync is enabled. Passive server receives builds from
#   primary and redirects current-passed-ci and current-tripleo to buildlogs.
#   Defaults to parameter dlrn::server_type
#
# [*db_connection*]
#   (optional) Specify a database connection string, using the SQLAlchemy
#   syntax
#   Defaults to 'sqlite:///commits.sqlite'
#
# [*fallback_to_master*]
#   (optional) If set to true, DLRN will fall back to the master branch
#   for source repositories if the configured branch cannot be found, and
#   rpm-master for distgit repositories. If set to false, it will fail in
#   case the configured branch cannot be found.
#   Defaults to true
#
# [*nonfallback_branches*]
#   (optional) Defines a list of regular expressions of branches for
#   source and distgit repositories that should never fall back to other
#   branches, even if not present in the repository.
#   Defaults to '^master$,^rpm-master$'
#
# [*include_srpm_in_repo*]
#   (optional) If set to false, DLRN will exclude source RPMs from the
#   generated repositories.
#   Defaults to true
#
# [*pkginfo_driver*]
#   (optional) DLRN driver to use to manage the distgit repositories.
#   The current available options are 'dlrn.drivers.rdoinfo.RdoInfoDriver',
#   'dlrn.drivers.gitrepo.GitRepoDriver' and
#   'dlrn.drivers.downstream.DownstreamInfoDriver'
#   Defaults to 'dlrn.drivers.rdoinfo.RdoInfoDriver'
#
# [*build_driver*]
#   (optional) DLRN driver used to build packages. The current available
#   options are 'dlrn.drivers.mockdriver.MockBuildDriver',
#   'dlrn.drivers.kojidriver.KojiBuildDriver' and
#   'dlrn.drivers.coprdriver.CoprBuildDriver'.
#   Defaults to 'dlrn.drivers.mockdriver.MockBuildDriver'.
#
# [*gitrepo_repo*]
#   (optional) If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this
#   option must be specified, and is the Git repo to use as a source.
#   Defaults to 'http://github.com/openstack/rpm-packaging'
#
# [*gitrepo_dir*]
#   (optional) If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this
#   option must be specified, and it is the directory inside gitrepo_repo where
#   the spec files area located
#   Defaults to '/openstack'
#
# [*gitrepo_skip*]
#   (optional) If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this
#   option must be specified, and it is a list of directories inside
#   gitrepo_dir to be skipped by the gitrepo driver, when finding packages to
#   be built
#   Defaults to ['openstack-macros']
#
# [*gitrepo_use_version_from_spec*]
#   (optional) If pkginfo_driver is 'dlrn.drivers.gitrepo.GitRepoDriver', this
#   option specifies whether the gitrepo driver will parse the spec file and
#   use the version from it as source-branch or not.
#   Defaults to true
#
# [*downstream_distroinfo_repo*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the
#   distroinfo repository to get package information from.
#   Defaults to undef
#
# [*downstream_info_files*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the
#   info file (or a list of info files) to get package information from,
#   within the distroinfo repo.
#   Defaults to undef.
#
# [*downstream_versions_url*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the
#   URL of a versions.csv file generated by another DLRN instance.
#   distro_hash and commit_hash will be reused from supplied versions.csv and
#   only packages present in the file are processed.
#   Defaults to undef.
#
# [*downstream_distro_branch*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option specifies the
#   branch to use when cloning the downstream distgit, since it may be
#   different from the upstream distgit branch.
#   Defaults to undef.
#
# [*downstream_tag*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option will filter
#   the 'packages' section of packaging metadata (from 'repo/info_files') to
#   only contain packages with the 'downstream_tag' tag. This tag will be
#   filtered in addition to the one set in the 'DEFAULT/tags' section.
#   Defaults to undef.
#
# [*downstream_distgit_key*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option will specify
#   the key used to find the downstream distgit in the 'packages' section of
#   packaging metadata (from 'repo/info_files').
#   Defaults to undef.
#
# [*use_upstream_spec*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option defines if the
#   upstream distgit contents (spec file and additional files) should be copied
#   over the downstream distgit after cloning.
#   Defaults to false.
#
# [*downstream_spec_replace_list*]
#   (optional) If pkginfo_driver is
#   'dlrn.drivers.downstream.DownstreamInfoDriver', this option will perform some
#   sed-like edits in the spec file after copying it from the upstream to the
#   downstream distgit. This is specially useful when the downstream DLRN instance
#   has special requirements, such as building without documentation.
#   Defaults to undef
#
# [*koji_exe*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this option defines the executable to use. Some Koji instances create
#   their own client packages to add their default configuration, such as CBS
#   or Brew.
#   Defaults to 'koji'
#
# [*koji_krb_principal*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this option defines the Kerberos principal to use for the Koji builds.
#   If it is set to undef, DLRN will assume that authentication is performed
#   using SSL certificates.
#   Defaults to undef.
#
# [*koji_krb_keytab*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this is the full path to a Kerberos keytab file, which contains the
#   Kerberos credentials for the principal defined in the koji_krb_principal
#   option.
#   Defaults to undef.
#
# [*koji_scratch_builds*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this option defines if a scratch build should be used.
#   Defaults to true.
#
# [*koji_build_target*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this option defines the build target to use. This defines the buildroot
#   and base repositories to be used for the build.
#   Defaults to undef.
#
# [*koji_arch*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   this option defines an override to the default architecture (x86_64)
#   in some cases (e.g retrieving mock configuration from Koji instance).
#   Defaults to 'x86_64'.
#
# [*koji_fetch_mock_config*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   when this option is set to true, DLRN will download the mock configuration
#   for the build target from Koji, and use it when building the source RPM.
#   If set to 'false', DLRN will use its internally defined mock
#   configuration, based on the ``DEFAULT/target`` configuration option.
#   Defaults to false.
#
# [*koji_use_rhpkg*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver',
#   when this option is set to true, 'rhpkg' will be used by DLRN as the build
#   tool in combination with 'koji_exe'.
#   Defaults to false.
#
# [*koji_mock_base_packages*]
#   (optional) If build_driver is 'dlrn.drivers.kojidriver.KojiBuildDriver'
#   and 'fetch_mock_config' is set to true, this option will define the set
#   of base packages that will be installed in the mock configuration when
#   creating the source RPM. This list of packages will override the one
#   fetched in the mock configuration, if set. If not set, no overriding will
#   be done.
#   Defaults to undef
#
# [*enable_deps_sync*]
#   (optional) Enable a cron job to periodically synchronize dependencies repo
#   with cloud7-openstack-<release>-testing CBS tag.
#   Defaults to false
#
# [*enable_brs_sync*]
#   (optional) Enable a cron job to periodically synchronize build requirements repo
#   with cloud{centos-release}-openstack-<release>-el{centos-release}-build CBS tag.
#   Defaults to false
#
# === Example
#
#  dlrn::worker {'centos-master':
#    distro            => 'centos7',
#    target            => 'centos',
#    distgit_branch    => 'rpm-master',
#    distro_branch     => 'master',
#    uid               => 1000,
#    disable_email     => true,
#    enable_cron       => false,
#    release           => 'ocata',
#    enable_deps_sync  => false,
#    enable_brs_sync   => false,
#  }

define dlrn::worker (
  $distro,
  $target,
  $distgit_branch                = 'rpm-master',
  $distro_branch                 = 'master',
  $uid                           = undef,
  $disable_email                 = true,
  $mock_tmpfs_enable             = false,
  $enable_cron                   = false,
  $cron_env                      = '',
  $cron_hour                     = '*',
  $cron_minute                   = '*/5',
  $enable_purge                  = false,
  $purge_hour                    = '1',
  $purge_minute                  = '7',
  $symlinks                      = undef,
  $release                       = 'rocky',
  $baseurl                       = 'http://localhost',
  $gerrit_user                   = undef,
  $gerrit_email                  = undef,
  $gerrit_topic                  = 'rdo-FTBFS',
  $rsyncdest                     = undef,
  $rsyncport                     = 22,
  $enable_public_rsync           = false,
  $public_rsync_hosts_allow      = undef,
  $server_type                   = $dlrn::server_type,
  $db_connection                 = 'sqlite:///commits.sqlite',
  $fallback_to_master            = true,
  $include_srpm_in_repo          = true,
  $nonfallback_branches          = '^master$,^rpm-master$',
  $worker_processes              = 1,
  $use_components                = false,
  $pkginfo_driver                = 'dlrn.drivers.rdoinfo.RdoInfoDriver',
  $build_driver                  = 'dlrn.drivers.mockdriver.MockBuildDriver',
  $gitrepo_repo                  = 'http://github.com/openstack/rpm-packaging',
  $gitrepo_dir                   = '/openstack',
  $gitrepo_skip                  = ['openstack-macros'],
  $gitrepo_use_version_from_spec = true,
  $downstream_distroinfo_repo    = undef,
  $downstream_info_files         = undef,
  $downstream_versions_url       = undef,
  $downstream_distro_branch      = undef,
  $downstream_tag                = undef,
  $downstream_distgit_key        = undef,
  $use_upstream_spec             = false,
  $downstream_spec_replace_list  = undef,
  $koji_exe                      = 'koji',
  $koji_krb_principal            = undef,
  $koji_krb_keytab               = undef,
  $koji_scratch_builds           = true,
  $koji_build_target             = undef,
  $koji_arch                     = 'x86_64',
  $koji_fetch_mock_config        = false,
  $koji_use_rhpkg                = false,
  $koji_mock_base_packages       = undef,
  $enable_deps_sync              = false,
  $enable_brs_sync               = false,

) {
  user { $name:
    comment    => "User for ${name} worker",
    groups     => ['users', 'mock'],
    home       => "/home/${name}",
    managehome => true,
    uid        => $uid,
  }

  file {"/home/${name}":
    ensure => directory,
    owner  => $name,
    mode   => '0755',
  }
  -> exec { "ensure home contents belong to ${name}":
    command => "chown -R ${name}:${name} /home/${name}",
    path    => '/usr/bin',
    unless  => "stat -c %U:%G /home/${name} | grep -w ${name}:${name} > /dev/null",
    timeout => 900,
  }
  -> file { "/home/${name}/data":
    ensure => directory,
    mode   => '0755',
    owner  => $name,
    group  => $name,
  }
  -> file { "/home/${name}/data/repos":
    ensure => directory,
    mode   => '0755',
    owner  => $name,
    group  => $name,
  }
  -> file { "/home/${name}/data/repos/dlrn-deps.repo":
    ensure => present,
    source => "puppet:///modules/dlrn/${name}-dlrn-deps.repo",
    mode   => '0644',
    owner  => $name,
    group  => $name,
  }
  -> file {"/home/${name}/data/repos/delorean-deps.repo":    # Compat symlink
    ensure => link,
    target => "/home/${name}/data/repos/dlrn-deps.repo",
  }
  # We only have current-tripleo-rdo in some workers
  if $name =~ /^(centos|centos8)\-(ocata|pike|queens|rocky|stein|train|ussuri|master-uc)/ {
    file {"/home/${name}/data/repos/current-passed-ci":    # Use current-tripleo-rdo as source of truth
      ensure  => link,
      target  => "/home/${name}/data/repos/current-tripleo-rdo",
      require => File["/home/${name}/data/repos"],
    }
  }

  if $enable_deps_sync {

    $deps_dirs = [
      "/home/${name}/data/repos/deps",
      "/home/${name}/data/repos/deps/latest",
      "/home/${name}/data/repos/deps/latest/SRPMS",
      "/home/${name}/data/repos/deps/latest/aarch64",
      "/home/${name}/data/repos/deps/latest/noarch",
      "/home/${name}/data/repos/deps/latest/ppc64le",
      "/home/${name}/data/repos/deps/latest/ppc64",
      "/home/${name}/data/repos/deps/latest/x86_64",
    ]

    file { $deps_dirs:
      ensure  => directory,
      mode    => '0755',
      owner   => $name,
      group   => $name,
      require => File["/home/${name}/data/repos"],
    }
  }

  if $enable_brs_sync {

    $build_deps_dirs = [
      "/home/${name}/data/repos/build-deps",
      "/home/${name}/data/repos/build-deps/latest",
      "/home/${name}/data/repos/build-deps/latest/SRPMS",
      "/home/${name}/data/repos/build-deps/latest/aarch64",
      "/home/${name}/data/repos/build-deps/latest/noarch",
      "/home/${name}/data/repos/build-deps/latest/ppc64le",
      "/home/${name}/data/repos/build-deps/latest/ppc64",
      "/home/${name}/data/repos/build-deps/latest/x86_64",
    ]

    file { $build_deps_dirs:
      ensure  => directory,
      mode    => '0755',
      owner   => $name,
      group   => $name,
      require => File["/home/${name}/data/repos"],
    }

    -> file { "/home/${name}/data/repos/rdo-trunk-runtime-deps.repo":
      ensure => present,
      source => "puppet:///modules/dlrn/${name}-rdo-trunk-runtime-deps.repo",
      mode   => '0644',
      owner  => $name,
      group  => $name,
    }
  }

  exec { "${name}-sshkeygen":
    command => "ssh-keygen -t rsa -P \"\" -f /home/${name}/.ssh/id_rsa",
    path    => '/usr/bin',
    creates => "/home/${name}/.ssh/id_rsa",
    user    => $name,
  }

  exec { "venv-${name}":
    command => "virtualenv --system-site-packages /home/${name}/.venv",
    path    => '/usr/bin',
    creates => "/home/${name}/.venv",
    cwd     => "/home/${name}",
    user    => $name,
  }

  vcsrepo { "/home/${name}/dlrn":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/softwarefactory-project/DLRN',
    user     => $name,
    require  => File["/home/${name}"]
  }

  file { "/home/${name}/setup_dlrn.sh":
    ensure  => present,
    mode    => '0755',
    content => "source /home/${name}/.venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py install",
  }

  if $disable_email {
    $dlrn_mailserver = ''
  } else {
    $dlrn_mailserver = 'localhost'
  }

  exec { "pip-install-${name}":
    command => "/home/${name}/setup_dlrn.sh",
    cwd     => "/home/${name}/dlrn",
    path    => '/usr/bin',
    creates => "/home/${name}/.venv/bin/dlrn",
    require => [Exec["venv-${name}"], Vcsrepo["/home/${name}/dlrn"], File["/home/${name}/setup_dlrn.sh"]],
    user    => $name,
  }

  augeas { "${name}-alembic.ini":
    incl    => "/home/${name}/dlrn/alembic.ini",
    lens    => 'Puppet.lns',
    changes => "set alembic/sqlalchemy.url ${db_connection}",
    require => Vcsrepo["/home/${name}/dlrn"],
  }

  file { "/usr/local/share/dlrn/${name}":
    ensure => directory,
    owner  => $name,
    group  => $name,
    mode   => '0700',
  }
  -> file { "/usr/local/share/dlrn/${name}/projects.ini":
    ensure  => present,
    content => template('dlrn/projects.ini.erb'),
    owner   => $name,
    group   => $name,
    mode    => '0600'
  }

  sudo::conf { $name:
      priority => 10,
      content  => "${name} ALL=(ALL) NOPASSWD: /bin/rm",
  }

  cron { "${name}-logrotate":
    command => "/usr/bin/find /home/${name}/dlrn-logs/*.log -mtime +2 -exec rm {} \\;",
    user    => $name,
    hour    => '4',
    minute  => '0'
  }


  if $enable_cron and $server_type == 'primary' {
    cron { $name:
      command => "DLRN_ENV=${cron_env} /usr/local/bin/run-dlrn.sh",
      user    => $name,
      hour    => $cron_hour,
      minute  => $cron_minute,
    }
  }

  if $enable_purge and $server_type == 'primary' {
    cron { "${name}-purge":
      command => '/usr/local/bin/run-purge.sh',
      user    => $name,
      hour    => $purge_hour,
      minute  => $purge_minute,
    }
  }

  if $enable_deps_sync and $server_type == 'primary' {
    cron { "${name}-deps":
      command => '/usr/local/bin/update-deps.sh > $HOME/dlrn-logs/update-deps-$(date +\%Y\%m\%d\%H\%M).log 2>&1',
      user    => $name,
      hour    => '*',
      minute  => [10, 40],
    }
  }

  if $enable_brs_sync and $server_type == 'primary' {
    cron { "${name}-build-deps":
      command => 'TAG_PHASE="build" DEPS_DIR="${HOME}/data/repos/build-deps/" /usr/local/bin/update-deps.sh > $HOME/dlrn-logs/update-build-deps-$(date +\%Y\%m\%d\%H\%M).log 2>&1',
      user    => $name,
      hour    => '*',
      minute  => [25, 55],
    }
  }

  if $enable_deps_sync or $enable_brs_sync {
      # FIXME(jpena): The centos-packager package is not available for RHEL 8 yet,
      #               so we cannot enable enable_deps_sync or enable_brs_sync
      if $::operatingsystem == 'Fedora' {
        # We need to enable a Copr repo for centos-packager in Fedora
        exec { 'Enable Copr repo for centos-packager':
          command => 'dnf copr enable bstinson/centos-packager -y',
          path    => '/usr/bin',
          unless  => 'grep enabled=1 /etc/yum.repos.d/_copr_bstinson-centos-packager.repo',
        }
        Exec['Enable Copr repo for centos-packager'] -> Package['centos-packager']
      }
      # (amoralej) - centos-packager for CentOS 8 is pulled from copr project.
      if ($::operatingsystem == 'CentOS') and (versioncmp($::operatingsystemmajrelease, '8') == 0) {
        ensure_resource('exec', 'Enable Copr repo for centos-packager in CentOS8', {
          command => 'dnf copr enable ykarel/ykarel-centos-stream centos-stream-x86_64 -y',
          path    => '/usr/bin',
          'unless'  => 'grep enabled=1 /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ykarel:ykarel-centos-stream.repo',
        })
        Exec['Enable Copr repo for centos-packager in CentOS8'] -> Package['centos-packager']
      }
      ensure_packages(['centos-packager'], {'ensure' => 'present'})

      # Enable deps purge cron job if $enable_purge is True
      if $enable_purge {
        cron { "${name}-deps-purge":
          command => '/usr/local/bin/purge-deps.sh',
          user    => $name,
          hour    => '3',
          minute  => '0',
        }
      }
  }

  # Set up symlinks
  if $symlinks {
    file { $symlinks :
      ensure  => link,
      target  => "/home/${name}/data/repos",
      require => Package['httpd'],
    }
  }

  # Special case for centos-master-uc
  if $name == 'centos-master-uc' {
    $worker_os      = 'centos'
    $worker_version = 'master-uc'
    $worker_name = 'centos-master-uc'
    file { "/home/${name}/dlrn/scripts/${worker_os}-${worker_version}.cfg":
      ensure  => present,
      content => template("dlrn/${worker_os}.cfg.erb"),
      require => Vcsrepo["/home/${name}/dlrn"],
    }
  }

  # Special case for centos8-master-uc
  if $name == 'centos8-master-uc' {
    $worker_os      = 'centos8'
    $worker_version = 'master-uc'
    $worker_name = 'centos8-master-uc'
    file { "/home/${name}/dlrn/scripts/${worker_os}-${worker_version}.cfg":
      ensure  => present,
      content => template("dlrn/${worker_os}.cfg.erb"),
      require => Vcsrepo["/home/${name}/dlrn"],
    }
  }

  # Special case for *-train, *-stein, *-rocky, *-queens, *-pike, and *-ocata
  if $name =~ /^(centos|centos8|fedora|rhel8)\-(ocata|pike|queens|rocky|stein|train|ussuri)/ {
    $components     = split($name, '-')
    $worker_os      = $components[0]
    $worker_version = $components[1]
    $worker_name    = "${worker_os}-${worker_version}"

    file { "/home/${name}/dlrn/scripts/${worker_os}-${worker_version}.cfg":
      ensure  => present,
      content => template("dlrn/${worker_os}.cfg.erb"),
      require => Vcsrepo["/home/${name}/dlrn"],
    }

    ensure_resource('file', "/var/www/html/${worker_version}", {
                        'ensure' => 'directory',
                        'mode' => '0755',
                        'path' => "/var/www/html/${worker_version}",
                        'require' => 'Package[httpd]'})
  }

  # Special case for centos-master and fedora-master
  if $name =~ /^(centos|centos8|fedora|rhel8)\-master$/ {
    $components     = split($name, '-')
    $worker_os      = $components[0]
    $worker_name    = "${worker_os}-master"

    file { "/home/${name}/dlrn/scripts/${worker_os}.cfg":
      ensure  => present,
      content => template("dlrn/${worker_os}.cfg.erb"),
      require => Vcsrepo["/home/${name}/dlrn"],
    }
  }

  # Set up gerrit, if configured
  if $gerrit_user and $server_type == 'primary' {
    if ! $gerrit_email {
        fail("gerrit_email not set, but gerrit_user is set to ${gerrit_user}")
    }

    exec { "Set gerrit user for ${name}":
      command     => "git config --global --add gitreview.username ${gerrit_user}",
      path        => '/usr/bin',
      user        => $name,
      cwd         => "/home/${name}",
      environment => "HOME=/home/${name}",
      unless      => "git config --get gitreview.username | grep -w ${gerrit_user}",
      require     => File["/home/${name}"],
    }

    exec { "Set git user for ${name}":
      command     => "git config --global user.name ${gerrit_user}",
      path        => '/usr/bin',
      user        => $name,
      cwd         => "/home/${name}",
      environment => "HOME=/home/${name}",
      unless      => "git config --get user.name | grep -w ${gerrit_user}",
      require     => File["/home/${name}"],
    }

    exec { "Set git email for ${name}":
      command     => "git config --global user.email ${gerrit_email}",
      path        => '/usr/bin',
      user        => $name,
      cwd         => "/home/${name}",
      environment => "HOME=/home/${name}",
      unless      => "git config --get user.email | grep -w ${gerrit_email}",
      require     => File["/home/${name}"],
    }

    ensure_resource('sshkey','review.rdoproject.org', {
      name    => '[review.rdoproject.org]:29418',
      ensure  => present,
      type    => 'rsa',
      key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCcv42F0KURajhaHpXECtonyhyxyyIexl0eJvKCTnc6hCE2bf8Iymw/xQIxmIwoibFunSC74tZe2t7Zy+yf3nLeNgE3T8+79yNxA2N4cJuY1T51haE5T1LKTMEkPkA4ucS8Lvd7KiXeTWRqOUQtLDWiZSZxPILzlb13AQ1M2s4U3X0M7SBt4V27ezDe34OQbBHMAGVQOKZhQkNVp3e5gmMfPlE3FifjQ07RI2fyG8v/r4A8on9n/g8Ge0vbDyGR0Ejt314MJ9JpzQTSPzw05UkjJYE7Knw3sHyBU9qIFHEm1Gw4z0PukiuINUmnBDVkf9ep6IsIw4JSvzNQbaLO9t99',
    })
  }

  # Prepare API stuff, it may be needed
  file { "/home/${name}/api":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["/home/${name}"],
  }
  -> file { "/usr/local/share/dlrn/${name}/acl.yml":
    ensure  => present,
    content => template('dlrn/acl.yml.erb'),
  }
  -> file { "/home/${name}/api/dlrn-api-${name}.wsgi":
    ensure  => present,
    content => template('dlrn/dlrn-api.wsgi.erb'),
  }
  -> file { "/home/${name}/api/dlrn-api-${name}.cfg":
    ensure  => present,
    content => template('dlrn/dlrn-api.cfg.erb'),
    owner   => $name,
    group   => $name,
    mode    => '0600',
  }

  # Enable public rsync module, if needed
  if $enable_public_rsync {
    include ::rsync::server

    if $name == 'centos-master-uc' {
      $rsync_module_name = $distro
    } else {
      $name_components   = split($name, '-')
      $rsync_module_name = "${name_components[0]}-${name_components[1]}"
    }

    rsync::server::module { $rsync_module_name:
      path            => "/home/${name}/data/repos",
      comment         => "${rsync_module_name} repositories",
      incoming_chmod  => false,
      outgoing_chmod  => false,
      uid             => 'nobody',
      gid             => 'nobody',
      max_connections => 4,
      hosts_allow     => $public_rsync_hosts_allow,
      require         => [File["/home/${name}/data/repos"], Package['rsync_package']]
    }
  }
}
