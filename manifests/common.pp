# == Class: delorean::common
#
# This class creates the common setup to any Delorean instance
#
# === Parameters:
#
# [*sshd_port*]
#   (optional) Additional port where sshd should listen
#   Defaults to 3300
#
# === Examples
#
#  class { 'delorean::common': }
#
# === Authors
#
# Javier Peña <jpena@redhat.com>

class delorean::common (
  $sshd_port              = 3300,
) {
  class { 'selinux':
    mode => 'permissive'
  }

  selinux_port { "tcp/${::delorean::common::sshd_port}":
    seltype => 'ssh_port_t',
  } ->
  class { 'ssh':
    server_options => {
      'Port' => [22, $::delorean::common::sshd_port],
    },
  }

  file { '/var/log/delorean':
    ensure => 'directory',
  }

  $required_packages = [ 'lvm2', 'xfsprogs', 'yum-utils', 'vim-enhanced',
                      'mock', 'rpm-build', 'git', 'python-pip',
                      'python-virtualenv', 'httpd', 'gcc', 'createrepo',
                      'screen', 'python-tox', 'git-review', 'python-sh',
                      'logrotate', 'postfix', 'lsyncd', 'firewalld' ]
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
    changes => 'set inet_interfaces 127.0.0.1',
    notify  => Service['postfix'],
  }

  group {'mock':
    ensure  => 'present',
    members => ['root'],
  }

  service { 'network':
    ensure => 'running',
    enable => true,
  }

  service { 'firewalld':
    ensure  => 'running',
    enable  => true,
    require => Package['firewalld'],
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
    changes => 'set DNS1 8.8.8.8',
    notify  => Service['network'],
  }

  physical_volume { '/dev/vdb':
    ensure  => present,
    require => Package['lvm2'],
  } ->
  volume_group { 'vgdelorean':
    ensure           => present,
    physical_volumes => '/dev/vdb',
  } ->
  exec { 'activate vgdelorean':
    command => 'vgchange -a y vgdelorean',
    path    => '/usr/sbin',
    creates => '/dev/vgdelorean',
  } ->
  logical_volume { 'lvol1':
    ensure       => present,
    volume_group => 'vgdelorean',
  } ->
  filesystem { '/dev/vgdelorean/lvol1':
    ensure  => present,
    fs_type => 'ext4',
  } ->
  mount { '/home':
    ensure  => mounted,
    device  => '/dev/vgdelorean/lvol1',
    fstype  => 'ext4',
    options => 'defaults',
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

}
