# == Class: delorean::lsyncdconfig
#
#  This class sets up part of the configuration for lsyncd
#
# === Parameters:
#
# [*path*]
#   (required) Path to use for synchronization.
#     Note: the same path will be used for source and destination
#
# [*sshd_port*]
#   (required) Port where sshd is listening
#
# [*remoteserver*]
#   (optional) Remote server for synchronization
#     Defaults to 'backupserver.example.com'
#

define delorean::lsyncdconfig (
  $path,
  $sshd_port,
  $remoteserver = 'backupserver.example.com' ) {

  ::concat::fragment { "lsyncd.conf:sync:${title}":
    target  => 'lsyncd.conf',
    content => template('delorean/lsyncd.conf.erb'),
    order   => '200',
  }
}


