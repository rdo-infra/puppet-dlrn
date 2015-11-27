# == Class: delorean::web
#
#  This class sets up the web content for a Delorean instance
#

class delorean::web(
){

  wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/index.html':
    destination => '/var/www/html/index.html',
    cache_dir   => '/var/cache/wget',
    require     => Package['httpd'],
  }

  file { '/var/www/html/images':
    ensure  => directory,
    mode    => '0755',
    require => Package['httpd'],
  } ->
  wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/images/rdo-logo-white.png':
    destination => '/var/www/html/images/rdo-logo-white.png',
    cache_dir   => '/var/cache/wget',
    require     => Package['httpd'],
  }

  file { '/usr/local/bin/update-web-index.sh':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/delorean/update-web-index.sh',
  } ->
  cron { 'update-web-index':
    command => '/usr/local/bin/update-web-index.sh',
    user    => 'root',
    hour    => '3',
    minute  => '0',
  }
}

