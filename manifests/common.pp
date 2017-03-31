# == Class: dlrn::common
#
# This class creates the common setup to any DLRN instance
#
# === Parameters:
#
# [*sshd_port*]
#   (optional) Additional port where sshd should listen
#   Defaults to 3300
#
# [*mock_tmpfs_enable*]
#   (optional) Enable the mock tmpfs plugin. Note this requires a lot of RAM
#   Defaults to false
#
# [*enable_https*]
#   (optional) Enable ssl in apache configuration.
#   Defaults to false
#
# === Examples
#
#  class { 'dlrn::common': }
#
# === Authors
#
# Javier Peña <jpena@redhat.com>

class dlrn::common (
  $sshd_port         = 3300,
  $mock_tmpfs_enable = false,
  $enable_https      = false,
) {
  class { 'selinux':
    mode => 'permissive'
  }

  selinux_port { "tcp/${::dlrn::common::sshd_port}":
    seltype => 'ssh_port_t',
  }
  -> class { 'ssh':
    server_options     => {
      'Port' => [22, $::dlrn::common::sshd_port],
    },
    validate_sshd_file => true,
  }

  $required_packages = [ 'lvm2', 'xfsprogs', 'yum-utils', 'vim-enhanced',
                      'mock', 'rpm-build', 'git', 'python-pip',
                      'python-virtualenv', 'gcc', 'createrepo',
                      'screen', 'python-tox', 'git-review', 'python-sh',
                      'postfix', 'firewalld', 'openssl-devel',
                      'libffi-devel', 'yum-plugin-priorities' ]
  package { $required_packages: ensure => 'installed', allow_virtual => true }

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
  }
  -> firewalld_service { 'Allow SSH':
    ensure  => 'present',
    service => 'ssh',
    zone    => 'public',
  }
  -> firewalld_service { 'Allow HTTP':
    ensure  => 'present',
    service => 'http',
    zone    => 'public',
  }
  -> firewalld_port { 'Allow custom SSH port':
    ensure   => present,
    zone     => 'public',
    port     => $sshd_port,
    protocol => 'tcp',
  }
  -> firewalld_service { 'Allow rsyncd':
    ensure  => 'present',
    service => 'rsyncd',
    zone    => 'public',
  }

  if $enable_https {
    firewalld_service { 'Allow HTTPS':
      ensure  => 'present',
      service => 'https',
      zone    => 'public',
    }
  }

  augeas { 'ifcfg-eth0':
    context => '/files/etc/sysconfig/network-scripts/ifcfg-eth0',
    changes => 'set DNS1 8.8.8.8',
    notify  => Service['network'],
  }

  # Only create vgdelorean in vdb if it exists
  # Note we are keeping the VG name to avoid issues if applying to an already
  # existing environment
  if member(split($::blockdevices,','),'vdb') {
    physical_volume { '/dev/vdb':
      ensure  => present,
      require => Package['lvm2'],
    }
    -> volume_group { 'vgdelorean':
      ensure           => present,
      physical_volumes => '/dev/vdb',
    }
    -> exec { 'activate vgdelorean':
      command => 'vgchange -a y vgdelorean',
      path    => '/usr/sbin',
      creates => '/dev/vgdelorean',
    }
    -> logical_volume { 'lvol1':
      ensure       => present,
      volume_group => 'vgdelorean',
    }
    -> filesystem { '/dev/vgdelorean/lvol1':
      ensure  => present,
      fs_type => 'ext4',
    }
    -> mount { '/home':
      ensure  => mounted,
      device  => '/dev/vgdelorean/lvol1',
      fstype  => 'ext4',
      options => 'defaults',
      require => Filesystem['/dev/vgdelorean/lvol1'],
    }
  }


  file { '/etc/sysctl.d/00-disable-ipv6.conf':
    ensure => present,
    source => 'puppet:///modules/dlrn/00-disable-ipv6.conf',
    mode   => '0644',
    notify => Exec['sysctl-p'],
  }

  exec { 'sysctl-p':
    command     => 'sysctl -p /etc/sysctl.d/*',
    path        => '/usr/sbin',
    refreshonly => true,
  }

  file { '/usr/local/share/dlrn':
    ensure => directory,
    mode   => '0755'
  }

  file { '/usr/local/bin/run-dlrn.sh':
    ensure => present,
    source => 'puppet:///modules/dlrn/run-dlrn.sh',
    mode   => '0755',
  }

  file { '/usr/local/bin/run-purge.sh':
    ensure => present,
    source => 'puppet:///modules/dlrn/run-purge.sh',
    mode   => '0755',
  }

  file { '/root/fix-fails.sql':
    ensure => present,
    source => 'puppet:///modules/dlrn/fix-fails.sql',
    mode   => '0600',
  }

  yum::config { 'timeout':
    ensure => 120,
  }

  class { 'sudo':
    purge               => false,
    config_file_replace => false,
  }

  class { 'rsync::server':
    use_xinetd => false,
  }

  if $mock_tmpfs_enable {
    file { '/etc/mock/site-defaults.cfg':
      ensure  => present,
      backup  => true,
      source  => 'puppet:///modules/dlrn/site-defaults.cfg',
      mode    => '0644',
      owner   => 'root',
      group   => 'mock',
      require => Package['mock'],
    }
  }
}
