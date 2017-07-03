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
#   (required) Mock target (fedora, centos, fedora-rawhide, centos-newton...)
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
#   Defaults to 'newton'
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
# [*worker_processes*]
#   (optional) Number of worker processes to use during build.
#   Defaults to 1
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
#   Detaults to true
#
# [*pkginfo_driver*]
#   (optional) DLRN driver to use to manage the distgit repositories.
#   The current available options are 'dlrn.drivers.rdoinfo.RdoInfoDriver'
#   and 'dlrn.drivers.gitrepo.GitRepoDriver'
#   Defaults to 'dlrn.drivers.rdoinfo.RdoInfoDriver'
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
# === Example
#
#  dlrn::worker {'centos-master':
#    distro         => 'centos7',
#    target         => 'centos',
#    distgit_branch => 'rpm-master',
#    distro_branch  => 'master',
#    uid            => 1000,
#    disable_email  => true,
#    enable_cron    => false,
#    release        => 'ocata',
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
  $release                       = 'newton',
  $baseurl                       = 'http://localhost',
  $gerrit_user                   = undef,
  $gerrit_email                  = undef,
  $gerrit_topic                  = 'rdo-FTBFS',
  $rsyncdest                     = undef,
  $rsyncport                     = 22,
  $server_type                   = $dlrn::server_type,
  $db_connection                 = 'sqlite:///commits.sqlite',
  $fallback_to_master            = true,
  $worker_processes              = 1,
  $pkginfo_driver                = 'dlrn.drivers.rdoinfo.RdoInfoDriver',
  $gitrepo_repo                  = 'http://github.com/openstack/rpm-packaging',
  $gitrepo_dir                   = '/openstack',
  $gitrepo_skip                  = ['openstack-macros'],
  $gitrepo_use_version_from_spec = true,
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
  # We want to make the user's home directory accessible to httpd, so the API
  # can handle stuff in there.
  -> selinux::fcontext { "${name}-data-context":
    seltype  => 'httpd_sys_rw_content_t',
    pathspec => "/home/${name}/data(/.*)?",
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
  if $name =~ /^centos\-(ocata|pike|queens|master-uc)/ {
    file {"/home/${name}/data/repos/current-passed-ci":    # Use current-tripleo-rdo as source of truth
      ensure  => link,
      target  => "/home/${name}/data/repos/current-tripleo-rdo",
      require => File["/home/${name}/data/repos"],
    }
  }

  exec { "${name}-sshkeygen":
    command => "ssh-keygen -t rsa -P \"\" -f /home/${name}/.ssh/id_rsa",
    path    => '/usr/bin',
    creates => "/home/${name}/.ssh/id_rsa",
    user    => $name,
  }

  selinux::fcontext { "${name}-venv-context":
    seltype  => 'httpd_user_script_exec_t',
    pathspec => "/home/${name}/.venv(/.*)?",
  }
  -> exec { "venv-${name}":
    command => "virtualenv --system-site-packages /home/${name}/.venv",
    path    => '/usr/bin',
    creates => "/home/${name}/.venv",
    cwd     => "/home/${name}",
    user    => $name,
  }

  vcsrepo { "/home/${name}/dlrn":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/openstack-packages/DLRN',
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

  # Set up symlinks
  if $symlinks {
    file { $symlinks :
      ensure  => link,
      target  => "/home/${name}/data/repos",
      require => Package['httpd'],
    }
  }

  # Special case for fedora-rawhide-master
  if $name == 'fedora-rawhide-master' {
    $worker_name = 'fedora-rawhide'
    file { "/home/${name}/dlrn/scripts/fedora-rawhide.cfg":
      ensure  => present,
      mode    => '0644',
      owner   => $name,
      content => template('dlrn/fedora-rawhide.cfg.erb'),
      require => Vcsrepo["/home/${name}/dlrn"],
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

  # Special case for *-queens, *-pike, *-ocata and *-newton
  if $name =~ /^(centos|fedora)\-(newton|ocata|pike|queens)/ {
    $components     = split($name, '-')
    $worker_os      = $components[0]
    $worker_version = $components[1]
    $worker_name    = "${worker_os}-${worker_version}"

    file { "/home/${name}/dlrn/scripts/${worker_os}-${worker_version}.cfg":
      ensure  => present,
      content => template("dlrn/${worker_os}.cfg.erb"),
      require => Vcsrepo["/home/${name}/dlrn"],
    }

    file { "/var/www/html/${worker_os}-${worker_version}":
      ensure  => directory,
      mode    => '0755',
      path    => "/var/www/html/${worker_version}",
      require => Package['httpd'],
    }
  }

  # Special case for centos-master and fedora-master
  if $name =~ /^(centos|fedora)\-master$/ {
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
  -> file { "/home/${name}/api/dlrn-api-${name}.wsgi":
    ensure  => present,
    content => template('dlrn/dlrn-api.wsgi.erb'),
  }
  -> file { "/home/${name}/api/dlrn-api-${name}.cfg":
    ensure  => present,
    content => template('dlrn/dlrn-api.cfg.erb'),
  }

  # Restore the SELinux context for data and .venv
  selinux::exec_restorecon { "/home/${name}/data":
    require     => File["/home/${name}/data/repos/delorean-deps.repo"],
    refreshonly => false,
    unless      => '/usr/bin/ls -Zd /home/${name}/data | /usr/bin/grep -w httpd_sys_rw_content_t',
  }

  selinux::exec_restorecon { "/home/${name}/.venv":
    require     => Exec["pip-install-${name}"],
    refreshonly => false,
    unless      => '/usr/bin/ls -Zd /home/${name}/.venv | /usr/bin/grep -w httpd_user_script_exec_t',
  }
}
