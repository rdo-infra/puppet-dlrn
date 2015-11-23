# == Class: delorean::worker
#
#  This class sets up a Delorean worker
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
#   (optional) Enable cron jobs to run Delorean on the worker every 5 minutes
#   Defaults to false
#
# [*symlinks*]
#   (optional) List of directories to be symlinked under to the repo directory
#   Example: ['/var/www/html/f22','/var/www/html/f21']
#   Defaults to undef
#
# 
# === Example
#
#  delorean::worker {'centos-master':
#    distro         => 'centos7',
#    target         => 'centos',
#    distgit_branch => 'rpm-master',
#    distro_branch  => 'master',
#    uid            => 1000,
#    disable_email  => true,
#    enable_cron    => false,
#  }

define delorean::worker (
  $distro,
  $target,
  $distgit_branch = 'rpm-master',
  $distro_branch  = 'master',
  $uid            = undef,
  $disable_email  = true,
  $enable_cron    = false,
  $symlinks       = undef ) {

  user { "$name":
    comment    => $name,
    groups     => ['users', 'mock'],
    home       => "/home/$name",
    managehome => true,
    uid        => $uid,
  }


  file { "/home/$name":
    ensure  => directory,
    mode    => '0644',
    owner   => "$name",
    recurse => true,
    require => User["$name"],
  } ->
  file { "/home/$name/data":
    ensure => directory,
    mode   => '0755',
    owner  => "$name",
    group  => "$name",
  } ->
  file { "/home/$name/data/repos":
    ensure => directory,
    mode   => '0755',
    owner  => "$name",
    group  => "$name",
  } ->
  file { "/home/$name/data/repos/delorean-deps.repo":
    ensure => present,
    source => "puppet:///modules/delorean/$name-delorean-deps.repo",
    mode   => '0644',
    owner  => "$name",
    group  => "$name",
  }


  exec { "$name-sshkeygen":
    command     => "ssh-keygen -t rsa -P \"\" -f /home/$name/.ssh/id_rsa",
    path        => '/usr/bin',
    creates     => "/home/$name/.ssh/id_rsa",
    user        => "$name",
  } 

  exec { "venv-$name":
    command => "virtualenv /home/$name/.venv",
    path    => '/usr/bin',
    creates => "/home/$name/.venv",
    cwd     => "/home/$name",
    user    => "$name",
  }

  vcsrepo { "/home/$name/delorean":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/openstack-packages/delorean',
    user     => "$name",
  } 

  file { "/home/$name/setup_delorean.sh":
    ensure  => present,
    mode    => '0755',
    cwd     => "/home/$name",
    content => "source /home/$name/.venv/bin/activate
pip install -r requirements.txt
pip install -r test-requirements.txt
python setup.py develop",
  }

  if $disable_email {
    $delorean_mailserver = ""
  } else {
    $delorean_mailserver = "localhost"
  }


  exec { "pip-install-$name":
    command => "/home/$name/setup_delorean.sh",
    cwd     => "/home/$name/delorean",
    path    => '/usr/bin',
    creates => "/home/$name/.venv/bin/delorean",
    require => [Exec["venv-$name"],Vcsrepo["/home/$name/delorean"],File["/home/$name/setup_delorean.sh"]],
    user    => "$name",
  }
 
  file { "/usr/local/share/delorean/$name":
    ensure  => directory,
    mode    => '0755',
  } ->
  file { "/usr/local/share/delorean/$name/projects.ini":
    ensure  => present,
    content => template('delorean/projects.ini.erb'),
  }

  sudo::conf { "$name":
      priority => 10,
      content  => "$name ALL=(ALL) NOPASSWD: /bin/rm",
  }

  file { "/etc/logrotate.d/delorean-$name":
    ensure  => present,
    content => template('delorean/logrotate.erb'),
    mode    => '0644',
  }

  if $enable_cron {
    if $name == 'centos-kilo'{
      # Kilo is a special case
      cron { "$name":
        command => "/usr/local/bin/run-delorean-kilo.sh",
        user    => "$name",
        hour    => '*',
        minute  => '*/5'
      }
    } else {
      cron { "$name":
        command => "/usr/local/bin/run-delorean.sh",
        user    => "$name",
        hour    => '*',
        minute  => '*/5'
      }
   }
  }

  # Set up symlinks
  if $symlinks {
    file { $symlinks :
      ensure  => link,
      target  => "/home/$name/data/repos",
      require => Package['httpd'],
    }
  }

  # Set up synchronization
  if $::delorean::backup_server  {
    delorean::lsyncdconfig { "lsync-$name":
      path         => "/home/$name",
      sshd_port    => $::delorean::sshd_port,
      remoteserver => $::delorean::backup_server,
    }
  }

  # Apply patch to sh.py in venv, according to 
  # https://github.com/amoffat/sh/pull/237
  file { "/home/$name/sh_patch.txt":
    ensure => present,
    source => "puppet:///modules/delorean/sh_patch.txt",
    mode   => '0644',
    owner  => "$name",
    group  => "$name",
  } ->
  exec { "$name-venvpatch":
    command  => "patch -b -p1 < /home/$name/sh_patch.txt",
    path     => '/usr/bin',
    user     => "$name",
    cwd      => "/home/$name/.venv/lib/python2.7/site-packages/",
    creates  => "/home/$name/.venv/lib/python2.7/site-packages/sh.py.orig",
    requires => Exec["venv-$name"],
  }


  # Special case for fedora-rawhide-master
  if $name == 'fedora-rawhide-master' {
    file { "/home/$name/delorean/scripts/fedora-rawhide.cfg":
      ensure => present,
      source => 'puppet:///modules/delorean/fedora-rawhide.cfg',
      mode   => '0644',
      owner  => "$name",
    }
  }

  # Special case for *-liberty and *-kilo
  if $name =~ /^(centos|fedora)\-(kilo|liberty)/ {
    $components     = split($name, '-')
    $worker_os      = $components[0]
    $worker_version = $components[1]

    file { "/home/$name/delorean/scripts/$worker_os-$worker_version.cfg":
      ensure  => present,
      content => template("delorean/$worker_os.cfg.erb")
    }

    file { "/var/www/html/$worker_os-$worker_version":
      ensure  => directory,
      mode    => '0755',
      path    => "/var/www/html/$worker_version",
      require => Package['httpd'],
    }
  }
}

