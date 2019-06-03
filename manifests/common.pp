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
  $enable_https      = false,
) {
  class { 'selinux':
    mode => 'permissive'
  }

  selboolean { 'httpd_read_user_content':
    persistent => true,
    value      => on,
  }

  selboolean { 'httpd_enable_homedirs':
    persistent => true,
    value      => on,
  }

  selinux::port { 'allow-ssh-port':
    ensure   => 'present',
    seltype  => 'ssh_port_t',
    protocol => 'tcp',
    port     => $::dlrn::common::sshd_port,
  }
  -> class { 'ssh':
    server_options     => {
      'Port' => [22, $::dlrn::common::sshd_port],
    },
    validate_sshd_file => true,
  }

  case $::osfamily {
    'RedHat': {
      case $::operatingsystem {
        'RedHat', 'CentOS': {
          if (versioncmp($::operatingsystemmajrelease, '7') > 0) {
            # RHEL 8 or later
            # FIXME(jpena): we should add git-review, but it is not available yet
            $required_packages = ['lvm2', 'xfsprogs', 'yum-utils', 'vim-enhanced',
                                  'mock', 'rpm-build', 'git', 'python3-pip',
                                  'python3-virtualenv', 'gcc', 'createrepo_c',
                                  'screen', 'python3-tox',
                                  'postfix', 'firewalld', 'openssl-devel',
                                  'libffi-devel', 'dnf-plugins-core', 'rpmdevtools',
                                  'selinux-policy-devel']
          } else {
            $required_packages = ['lvm2', 'xfsprogs', 'yum-utils', 'vim-enhanced',
                                  'mock', 'rpm-build', 'git', 'python-pip',
                                  'python-virtualenv', 'gcc', 'createrepo',
                                  'screen', 'python-tox', 'git-review', 'python-sh',
                                  'postfix', 'firewalld', 'openssl-devel',
                                  'libffi-devel', 'yum-plugin-priorities', 'rpmdevtools',
                                  'selinux-policy-devel']
          }
        }
        default: {
          # Fedora
          $required_packages = ['lvm2', 'xfsprogs', 'yum-utils', 'vim-enhanced',
                                'mock', 'rpm-build', 'git', 'python-pip',
                                'python-virtualenv', 'gcc', 'createrepo',
                                'screen', 'python-tox', 'git-review', 'python-sh',
                                'postfix', 'firewalld', 'openssl-devel',
                                'libffi-devel', 'yum-plugin-priorities', 'rpmdevtools',
                                'selinux-policy-devel']
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, \
            puppet-dlrn only supports osfamily RedHat")
    }
  }
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

  if (versioncmp($::operatingsystemmajrelease, '8') < 0) {
    service { 'network':
      ensure => 'running',
      enable => true,
    }
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

  if $enable_https {
    firewalld_service { 'Allow HTTPS':
      ensure  => 'present',
      service => 'https',
      zone    => 'public',
    }
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

  file { '/usr/local/bin/update-deps.sh':
    ensure => present,
    source => 'puppet:///modules/dlrn/update-deps.sh',
    mode   => '0755',
  }

  file { '/usr/local/bin/purge-deps.sh':
    ensure => present,
    source => 'puppet:///modules/dlrn/purge-deps.sh',
    mode   => '0755',
  }
}
