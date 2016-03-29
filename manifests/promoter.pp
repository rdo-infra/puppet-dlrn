# == Class: delorean::promoter
#
#  This class sets up an promoter user for Delorean
#

class delorean::promoter (
) {

  user { 'promoter':
    comment    => 'rdoinfo user',
    groups     => ['users'],
    home       => '/home/promoter',
    managehome => true,
    require    => Mount['/home'],
  } ->
  file { '/home/promoter/.ssh':
    ensure => directory,
    mode   => '0700',
    owner  => 'promoter',
    group  => 'promoter',
  } ->
  file { '/home/promoter/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    owner   => 'promoter',
    group   => 'promoter',
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuT/KZPHtObx4d1GzI7OTG8sFEgyKJsiYl2PRhOL0ugknac8Cv2KHNTN0MgAI3AVCpJaZ+j4bcFWkLCfkj6zmsl0/j3IGn2qCL7YuBeZ5tbvVH1mr0upzwRu8IQSbcHEzSeuPgVpYwUVf/hp4fD7eGlW2vm1ONOljvFDe1DTAL74C0qj6xiu+G1+PSA+RHUhFayIg34TVSnfkUHi+Lq23rR+0CAIzaEI2ClqVVEySktmnP0Y/ZGGXtX0qCrMZd10jAHNWLQ8lTM92nlqamy5eWhMEnU4nnK09iyYtRB+HzcmSU7QZCC1raMbtGgqPsP+IxLJnnpZavNcK39s6uvfKOQ==\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC46NqCxedjvvaOI3JwtthzQGykXCdNmI4KegteROEBr2xM+0xws5RCawgnu8NTVQXDG+iQhzjOg/7fN/3/9xoZyaz20XxlJwbUtPUs5WG9TN00PDaKH5UxjMzwU3vSZT2i0HtaPMWBzxNV/aIptH1xGTXfn0ytGzeE3NfKOEah2PHgsDpayGrse4rjupYGYokIK/YGn5otEDNu2ho1xMYkba7kAPfmMA4j7NP3/NfO2p8Q+IEnMLjnPnbyoCSRP2jyrSFKfGKgYLq0A6jsjfZPAD6kXPpo9CoUTM1IW4AJ2f82ai9yT4NmmcLL69nFBap8Mfj/0k3PkBL315iQG7I/ tripleo-promoter",
  }

  file { '/usr/local/bin/promote.sh':
    ensure => present,
    source => 'puppet:///modules/delorean/promote.sh',
    mode   => '0755',
  }

  sudo::conf { 'promoter':
    priority => 99,
    content  => 'promoter ALL= NOPASSWD: /usr/local/bin/promote.sh',
    require  => User['promoter'],
  }

}
