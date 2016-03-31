# == Class: dlrn
#
# Configures a DLRN instance
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
#  class { 'dlrn': }
#
# === Authors
#
# Javier Peña <jpena@redhat.com>


class dlrn (
  $sshd_port              = 3300,
  $backup_server          = undef,
) {

  class { '::dlrn::common':
    sshd_port => $sshd_port,
  }

  class { '::dlrn::rdoinfo': }
  class { '::dlrn::promoter': }
  class { '::dlrn::fail2ban':
    sshd_port => $sshd_port,
  }
  class { '::dlrn::web': }

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

    Dlrn::Worker<||>       -> Service <| title == 'lsyncd' |>
    Dlrn::Lsyncdconfig<||> -> Service <| title == 'lsyncd' |>
  }

  $workers = hiera_hash('dlrn::workers')
  create_resources(dlrn::worker,$workers)

  Class['::dlrn::common'] -> Dlrn::Worker <||>
  Class['::dlrn::common'] -> Class['::dlrn::rdoinfo']
  Class['::dlrn::common'] -> Class['::dlrn::promoter']
}
