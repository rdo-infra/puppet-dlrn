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
  $backup_server          = undef,
) {

  class { '::delorean::common':
    sshd_port => $sshd_port,
  }

  class { '::delorean::rdoinfo': }
  class { '::delorean::promoter': }
  class { '::delorean::fail2ban':
    sshd_port => $sshd_port,
  }
  class { '::delorean::web': }

  if $backup_server {
    concat { 'lsyncd.conf':
      path  => '/etc/lsyncd.conf',
      owner => root,
      group => root,
      mode  => '0644',
    }

    service { 'lsyncd':
      ensure => 'running',
      enable => true,
    }

    Delorean::Worker<||>       -> Service <| title == 'lsyncd' |>
    Delorean::Lsyncdconfig<||> -> Service <| title == 'lsyncd' |>
  }

  $workers = hiera_hash('delorean::workers')
  create_resources(delorean::worker,$workers)

  Class['::delorean::common'] -> Delorean::Worker <||>
}
