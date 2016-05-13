# == Class: dlrn::web
#
#  This class sets up the web content for a DLRN instance
#

class dlrn::web(
  $enable_https = $dlrn::enable_https,
){

  if $enable_https {
    $cert_file  = '/etc/pki/tls/certs/trunk_rdoproject_org.crt'
    $cert_key   = '/etc/pki/tls/private/trunk.rdoproject.org.key'
    $cert_chain = '/etc/pki/tls/certs/DigiCertCA.crt'

    file {"$cert_file":
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    } ->
    file {"$cert_key":
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    } ->
    file {"$cert_chain":
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    }

    apache::vhost { 'ssl-trunk.rdoproject.org':
      port                 => 443,
      default_vhost        => true,
      override             => "FileInfo",
      docroot              => "/var/www/html",
      servername           => "default",
      ssl                  => true,
      ssl_cert             => $cert_file,
      ssl_key              => $cert_key,
      ssl_chain            => $cert_chain,
      ssl_protocol         => 'ALL -SSLv2 -SSLv3',
      ssl_honorcipherorder => 'on',
    }
  }

  class { 'apache': 
    default_vhost => false,
  } 

  apache::vhost { 'trunk.rdoproject.org':
    port          => 80,
    default_vhost => true,
    override      => "FileInfo", 
    docroot       => "/var/www/html",
    servername    => "default"
  } ->
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
    source => 'puppet:///modules/dlrn/update-web-index.sh',
  } ->
  cron { 'update-web-index':
    command => '/usr/local/bin/update-web-index.sh',
    user    => 'root',
    hour    => '3',
    minute  => '0',
  }
}

