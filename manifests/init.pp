# == Class: delorean
#
# Configures a Delorean instance
#
# === Parameters:
#
# [*sshd_port*]
#   (optional) Additional port where sshd should listen
#   Defaults to 3300
#
# [*disable_email*]
#   (optional) Disable e-mail notifications
#   Defaults to true
#
# [*enable_worker_cronjobs*]
#   (optional) Enable worker cron jobs
#   Defaults to false
#
# [*backup_server*]
#   (optional) If set, enable lsyncd daemon and use this host as the target
#     for synchronization
#   Defaults to undef
#
# === Examples
#
#  class { 'delorean': }
#
# === Authors
#
# Javier Peña <jpena@redhat.com>


class delorean (
  $sshd_port              = 3300,
  $disable_email          = true,
  $enable_worker_cronjobs = false,
  $backup_server          = undef,
) {

  class { 'selinux':
    mode => 'permissive'
  }

  selinux_port { "tcp/$::delorean::sshd_port":
    seltype => 'ssh_port_t',
  } ->
  class { 'ssh':
    server_options => {
      'Port' => [22, $::delorean::sshd_port],
    },
  }

  file { '/var/log/delorean':
    ensure => 'directory',
  }
 
  $required_packages = [ 'lvm2', 'xfsprogs', 'yum-utils', 'vim', 'mock',
                         'rpm-build', 'git', 'python-pip', 'git-remote-hg',
                         'python-virtualenv', 'httpd', 'gcc', 'createrepo',
                         'screen', 'python3', 'python-tox', 'git-review',
                         'logrotate', 'postfix', 'lsyncd' ]
  package { $required_packages: ensure => 'installed' }

  service { 'httpd':
    ensure  => 'running',
    enable  => true,
    require => Package['httpd'],
  }

  service { 'postfix':
    ensure  => 'running',
    enable  => true,
    require => Package['postfix'],
  }

  augeas { 'postfix.cf' :
    context => '/files/etc/postfix/main.cf',
    changes => "set inet_interfaces 127.0.0.1",
    notify  => Service['postfix'],
  }

  group {'mock':
    ensure  => 'present',
    members => ['root'],
  }

  service { 'network':
    ensure      => 'running',
    enable      => true,
  }

  service { 'firewalld':
    ensure      => 'running',
    enable      => true,
  } ->
  firewalld_service { 'Allow SSH':
    ensure  => 'present',
    service => 'ssh',
    zone    => 'public',
  } ->
  firewalld_service { 'Allow HTTP':
    ensure  => 'present',
    service => 'http',
    zone    => 'public',
  } ->
  firewalld_port { 'Allow custom SSH port':
    ensure   => present,
    zone     => 'public',
    port     => $sshd_port,
    protocol => 'tcp',
  }

  augeas { 'ifcfg-eth0':
    context => '/files/etc/sysconfig/network-scripts/ifcfg-eth0',    
    changes => "set DNS1 8.8.8.8",
    notify  => Service['network'],
  }

  physical_volume { '/dev/vdb':
    ensure  => present,
    require => Package['lvm2'],
  }

  volume_group { 'vgdelorean':
    ensure           => present,
    physical_volumes => '/dev/vdb',
  }

  logical_volume { 'lvol1':
    ensure       => present,
    volume_group => 'vgdelorean',
  }

  filesystem { '/dev/vgdelorean/lvol1':
    ensure  => present,
    fs_type => 'ext4',
  }

  mount { '/home':
    ensure  => present,
    device  => '/dev/vgdelorean/lvol1',
    fstype  => 'ext4',
    require => Filesystem['/dev/vgdelorean/lvol1'],
  }

  file { '/etc/sysctl.d/00-disable-ipv6.conf':
    ensure => present,
    source => 'puppet:///modules/delorean/00-disable-ipv6.conf',
    mode   => '0644',
    notify => Exec['sysctl-p'],
  }

  file { '/etc/sysctl.d/01-lsyncd-inotify.conf':
    ensure => present,
    source => 'puppet:///modules/delorean/01-lsyncd-inotify.conf',
    mode   => '0644',
    notify => Exec['sysctl-p'],
  }

  exec { 'sysctl-p':
    command     => 'sysctl -p /etc/sysctl.d/*',
    path        => '/usr/sbin',
    refreshonly => true,
  }
 
  file { '/usr/local/share/delorean':
    ensure => directory,
    mode   => '0755'
  }

  file { '/usr/local/bin/run-delorean.sh':
    ensure => present,
    source => 'puppet:///modules/delorean/run-delorean.sh',
    mode   => '0755',
  }

  file { '/usr/local/bin/run-delorean-kilo.sh':
    ensure => present,
    source => 'puppet:///modules/delorean/run-delorean-kilo.sh',
    mode   => '0755',
  }

  file { '/root/fix-fails.sql':
    ensure => present,
    source => 'puppet:///modules/delorean/fix-fails.sql',
    mode   => '0600',
  }

  file { '/root/README_SSL.txt':
    ensure => present,
    source => 'puppet:///modules/delorean/README_SSL.txt',
    mode   => '0600',
  }

  file { '/root/ssl_setup.sh':
    ensure => present,
    source => 'puppet:///modules/delorean/ssl_setup.sh',
    mode   => '0700',
  }

  yum::config { 'timeout':
    ensure => 120,
  }

  delorean::worker { 'fedora-master':
    distro         => 'f22',
    target         => 'fedora',
    distgit_branch => 'rpm-master',
    distro_branch  => 'master',
    disable_email  => $disable_email,
    enable_cron    => $enable_worker_cronjobs,
    symlinks       => ['/var/www/html/f22',
                       '/var/www/html/f21',
                       '/var/www/html/fedora22',
                       '/var/www/html/fedora21'],
  }

  delorean::worker { 'fedora-rawhide-master':
    distro         => 'f24',
    target         => 'fedora-rawhide',
    distgit_branch => 'rpm-master',
    distro_branch  => 'master',
    disable_email  => $disable_email,
    enable_cron    => $enable_worker_cronjobs,
    symlinks       => ['/var/www/html/f24','/var/www/html/fedora24'],
  }

  delorean::worker { 'centos-master':
    distro         => 'centos7',
    target         => 'centos',
    distgit_branch => 'rpm-master',
    distro_branch  => 'master',
    disable_email  => $disable_email,
    enable_cron    => $enable_worker_cronjobs,
    symlinks       => ['/var/www/html/centos7', '/var/www/html/centos70'],
  }

  delorean::worker { 'centos-liberty':
    distro         => 'centos7',
    target         => 'centos-liberty',
    distgit_branch => 'rpm-liberty',
    distro_branch  => 'stable/liberty',
    disable_email  => $disable_email,
    enable_cron    => $enable_worker_cronjobs,
    symlinks       => ['/var/www/html/centos7-liberty', '/var/www/html/liberty/centos7'],
  }

  delorean::worker { 'centos-kilo':
    distro         => 'centos7',
    target         => 'centos-kilo',
    distgit_branch => 'rpm-kilo',
    distro_branch  => 'stable/kilo',
    disable_email  => $disable_email,
    enable_cron    => $enable_worker_cronjobs,
    symlinks       => ['/var/www/html/centos7-kilo', '/var/www/html/kilo/centos7'],
  }

  Mount['/home'] -> Delorean::Worker <||>

  class { '::delorean::rdoinfo': }
  class { '::delorean::promoter': }
  class { '::delorean::fail2ban': 
    sshd_port => 3300,
  }
  class { '::delorean::web': }

  if $backup_server {
    concat { 'lsyncd.conf':
      path => '/etc/lsyncd.conf',
      owner => root,
      group => root,
      mode => '0644',
    } 

    service { 'lsyncd':
     ensure  => 'running',
     enable  => true,
    }   

    Delorean::Worker<||>       -> Service <| title == 'lsyncd' |>
    Delorean::Lsyncdconfig<||> -> Service <| title == 'lsyncd' |>
  }
}
