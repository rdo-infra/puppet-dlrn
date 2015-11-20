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

  file { "/var/www/html/images":
    ensure  => directory,
    mode    => '0755',
    require => Package['httpd'],
  } ->
  wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/images/rdo-logo-white.png':
    destination => '/var/www/html/images/rdo-logo-white.png',
    cache_dir   => '/var/cache/wget',
    require     => Package['httpd'],
  }
}

