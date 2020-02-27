# == Class: dlrn::promoter
#
#  This class sets up an promoter user for DLRN
#

class dlrn::promoter (
) {

  user { 'promoter':
    comment    => 'rdoinfo user',
    groups     => ['users'],
    home       => '/home/promoter',
    managehome => true,
  }
  -> file { '/home/promoter':
    ensure  => directory,
    owner   => 'promoter',
    group   => 'promoter',
    recurse => true,
  }
  -> file { '/home/promoter/.ssh':
    ensure => directory,
    mode   => '0700',
    owner  => 'promoter',
    group  => 'promoter',
  }
  -> file { '/home/promoter/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    owner   => 'promoter',
    group   => 'promoter',
    content => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH7MmSecn77eU98/MOEnNBfzNJwva+/0df/G3iWKfaNcGq7JrHmiujLnjrWSVKaRogDEVVmitFKcKSR1dlpHGCFFcN7Wh3JlayKekQknyNxn1jYa1oGOiT4dO9PKcWeDkyGjtBaODDRi4TV4eBRIzFg3yCIzMnl/GinZEKLafREKmySHfteID3U4F+u1pPcXk7NywN/E7xvmMaRa+vr0+mF1ulxx1OMED1wxsFy51AO3au+eTwoKd7ZrtX0XL3DyNE91aty9hUUMMlbhtpXLDof5SfYWFGuXPfn/AEOD2nbq4QrgZ9DXw+1CgxgAsW2GBZrVYOWI5FDWrvTIljMxfD cico_rhos_ci_key@ci.centos.org',
  }

  file { '/usr/local/bin/promote.sh':
    ensure => present,
    source => 'puppet:///modules/dlrn/promote.sh',
    mode   => '0755',
  }

  sudo::conf { 'promoter':
    priority => 99,
    content  => 'promoter ALL= NOPASSWD: /usr/local/bin/promote.sh',
    require  => User['promoter'],
  }

}
