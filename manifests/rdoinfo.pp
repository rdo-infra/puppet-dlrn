# == Class: delorean::rdoinfo
#
#  This class sets up an rdoinfo user for Delorean
#

class delorean::rdoinfo (
) {

  user { 'rdoinfo':
    comment    => 'rdoinfo user',
    groups     => ['users', 'mock'],
    home       => '/home/rdoinfo',
    managehome => true,
    require    => Mount['/home'],
  } ->
  file { '/home/rdoinfo':
    ensure => directory,
    mode   => '0755',
    owner  => 'rdoinfo',
  } ->
  vcsrepo { '/home/rdoinfo/rdoinfo':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/redhat-openstack/rdoinfo',
    user     => 'rdoinfo',
  }

  file { '/usr/local/bin/rdoinfo-update.sh':
    ensure => present,
    source => 'puppet:///modules/delorean/rdoinfo-update.sh',
    mode   => '0755',
  }

  cron { 'rdoinfo':
    command => '/usr/local/bin/rdoinfo-update.sh',
    user    => 'rdoinfo',
    hour    => '*',
    minute  => '7'
  }

}
