# == Class: dlrn::worker
#
#  This class sets up a DLRN worker
#
# === Parameters:
#
# [*distro*]
#   (required) Distro for worker (f22, centos7...)
#
# [*target*]
#   (required) Mock target (fedora, centos, fedora-rawhide, centos-liberty...)
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
# [*enable_cron*]
#   (optional) Enable cron jobs to run DLRN on the worker every 5 minutes
#   Defaults to false
#
# [*symlinks*]
#   (optional) List of directories to be symlinked under to the repo directory
#   Example: ['/var/www/html/f22','/var/www/html/f21']
#   Defaults to undef
#
# [*release*]
#   (optional) Release this worker will be using (all lowercase)
#   Example: 'mitaka'
#   Defaults to 'mitaka'
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
#    release        => 'mitaka',
#  }

define dlrn::worker (
  $distro,
  $target,
  $distgit_branch = 'rpm-master',
  $distro_branch  = 'master',
  $uid            = undef,
  $disable_email  = true,
  $enable_cron    = false,
  $symlinks       = undef,
  $release        = 'mitaka',
  $gerrit_user    = undef,
  $gerrit_email   = undef ) {

  user { $name:
    comment    => $name,
    groups     => ['users', 'mock'],
    home       => "/home/${name}",
    managehome => true,
    uid        => $uid,
  }

  file {"/home/${name}":
    ensure => directory,
    owner  => $name,
    mode   => '0755',
  } ->
  exec { "ensure home contents belong to ${name}":
    command => "chown -R ${name}:${name} /home/${name}",
    path    => '/usr/bin',
    timeout => 900,
  } ->
  file { "/home/${name}/data":
    ensure => directory,
    mode   => '0755',
    owner  => $name,
    group  => $name,
  } ->
  file { "/home/${name}/data/repos":
    ensure => directory,
    mode   => '0755',
    owner  => $name,
    group  => $name,
  } ->
  file { "/home/${name}/data/repos/dlrn-deps.repo":
    ensure => present,
    source => "puppet:///modules/dlrn/${name}-dlrn-deps.repo",
    mode   => '0644',
    owner  => $name,
    group  => $name,
  } ->
  # Compat symlink
  file {"/home/${name}/data/repos/delorean-deps.repo":
    ensure => link,
    target => "/home/${name}/data/repos/dlrn-deps.repo",
  }

  exec { "${name}-sshkeygen":
    command => "ssh-keygen -t rsa -P \"\" -f /home/${name}/.ssh/id_rsa",
    path    => '/usr/bin',
    creates => "/home/${name}/.ssh/id_rsa",
    user    => $name,
  }

  exec { "venv-${name}":
    command => "virtualenv /home/${name}/.venv",
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
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py develop",
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

  # Special case for non-master
  if $name =~ /^(centos|fedora)\-(kilo|liberty|mitaka)/ {
    $baseurl_components = split($distro_branch, '/')
    $baseurl_target     = "${distro}-${baseurl_components[1]}"
  } else {
    $baseurl_target = $distro
  }

  file { "/usr/local/share/dlrn/${name}":
    ensure => directory,
    mode   => '0755',
  } ->
  file { "/usr/local/share/dlrn/${name}/projects.ini":
    ensure  => present,
    content => template('dlrn/projects.ini.erb'),
  }

  sudo::conf { $name:
      priority => 10,
      content  => "${name} ALL=(ALL) NOPASSWD: /bin/rm",
  }

  file { "/etc/logrotate.d/dlrn-${name}":
    ensure  => present,
    content => template('dlrn/logrotate.erb'),
    mode    => '0644',
  }

  if $enable_cron {
    cron { $name:
      command => '/usr/local/bin/run-dlrn.sh',
      user    => $name,
      hour    => '*',
      minute  => '*/5'
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

  # Set up synchronization
  if $::dlrn::backup_server  {
    dlrn::lsyncdconfig { "lsync-${name}":
      path         => "/home/${name}",
      sshd_port    => $::dlrn::sshd_port,
      remoteserver => $::dlrn::backup_server,
    }
  }

  # Special case for fedora-rawhide-master
  if $name == 'fedora-rawhide-master' {
    file { "/home/${name}/dlrn/scripts/fedora-rawhide.cfg":
      ensure  => present,
      source  => 'puppet:///modules/dlrn/fedora-rawhide.cfg',
      mode    => '0644',
      owner   => $name,
      require => Vcsrepo["/home/${name}/dlrn"],
    }
  }

  # Special case for *-mitaka, *-liberty and *-kilo
  if $name =~ /^(centos|fedora)\-(kilo|liberty|mitaka)/ {
    $components     = split($name, '-')
    $worker_os      = $components[0]
    $worker_version = $components[1]

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

  # Set up gerrit, if configured
  if $gerrit_user {
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
  }
}
