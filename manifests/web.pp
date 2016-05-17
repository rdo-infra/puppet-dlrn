# == Class: dlrn::web
#
#  This class sets up the web content for a DLRN instance
#
# [*enable_https*]
#   (optional) Enable ssl in apache configuration (requires proper certificates
#   installed in the system.
#   Defaults to parameter dlrn::enable_https
#
# [*cert_file*]
#   (optional) Location of SSL encryption certificate if https is enabled.
#   Default is undef. Required if enable_https is true
#
# [*cert_key*]
#   (optional) Location of SSL encryption certificate key if https is enabled.
#   Default is undef. Required if enable_https is true
#
# [*cert_chain*]
#   (optional) Location of SSL chain if https is enabled.
#   Default is undef. Required if enable_https is true
#
# === Examples
#
#  class { 'dlrn::web':
#    enable_https => false 
#  }
#

class dlrn::web(
  $enable_https = $dlrn::enable_https,
  $cert_file    = undef,
  $cert_key     = undef,
  $cert_chain   = undef,
){

  if $enable_https {
    exec {"test -f $cert_file":
      path => "/usr/bin:/usr/sbin:/bin",
    }->
    file {"$cert_file":
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    }

    exec {"test -f $cert_key":
      path => "/usr/bin:/usr/sbin:/bin",
    }->
    file {"$cert_key":
      owner  => 'root',
      group  => 'root',
      mode   => '0600'
    }

    exec {"test -f $cert_chain":
      path => "/usr/bin:/usr/sbin:/bin",
    }->
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

