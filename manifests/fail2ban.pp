# == Class: delorean::fail2ban
#
#  This class sets up fail2ban for a Delorean instance
#
# === Parameters:
#
# [*sshd_port*]
#   (required) Additional port where sshd should listen

class delorean::fail2ban(
  $sshd_port
){
  $fail2ban_pkgs = ['fail2ban','fail2ban-systemd']

  package { $fail2ban_pkgs: ensure => 'installed' }

  file { '/etc/fail2ban/jail.d/01-sshd.conf':
    ensure  => present,
    mode    => '0644',
    content => "[sshd]
enabled = true
port = ${sshd_port}",
    require => Package['fail2ban'],
  } ->
  service { 'fail2ban':
    ensure  => 'running',
    enable  => true,
    require => Service['firewalld']
  }

}


