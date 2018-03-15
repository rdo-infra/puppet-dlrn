# == Class: dlrn::web
#
#  This class sets up the web content for a DLRN instance
#
# === Parameters:
#
# [*web_domain*]
#   (mandatory) domain name of the web server
#   example: trunk.rdoproject.org
#
# [*enable_https*]
#   (optional) Enable ssl in apache configuration. Certificates are managed
#   using letsencrypt service.
#   Defaults to false
#
# [*cert_mail*]
#   The email address to use to register with Let's Encrypt. Required if
#   enable_https is set to true.
#
# [*enable_api*]
#   (optional) Enable the DLRN API.
#   Defaults to false
#
# [*api_workers*]
#   (optional) If enable_api is true, this array will define which workers
#   will be added to the vhost configuration as WSGI. Each worker will have
#   a url of /api-${worker} associated to its WSGI script.
#   Example: ['centos-master-uc', 'centos-ocata']
#   Defaults to []

class dlrn::web(
  $web_domain,
  $enable_https = false,
  $cert_mail    = undef,
  $enable_api   = false,
  $api_workers  = [],
){

  class { 'apache':
    default_vhost => false,
  }

  file { '/var/www/html/images':
    ensure  => directory,
    mode    => '0755',
    require => Package['httpd'],
  }
  -> wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/images/rdo-logo-white.png':
    destination => '/var/www/html/images/rdo-logo-white.png',
    cache_dir   => '/var/cache/wget',
    require     => Package['httpd'],
  }

  file { '/usr/local/bin/update-web-index.sh':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/dlrn/update-web-index.sh',
  }
  -> cron { 'update-web-index':
    command => '/usr/local/bin/update-web-index.sh > /dev/null',
    user    => 'root',
    hour    => '3',
    minute  => '0',
  }

  if $enable_https {
    class { '::letsencrypt':
      configure_epel => false,
      email          => $cert_mail,
      package_name   => 'certbot',
    }
    letsencrypt::certonly { $web_domain :
      plugin               => 'webroot',
      webroot_paths        => [ '/var/www/html' ],
      domains              => [ $web_domain ],
      manage_cron          => true,
      cron_success_command => '/bin/systemctl reload httpd',
    }
    if $enable_api {
      include ::apache::mod::ssl
      apache::listen { '443': }

      apache::vhost::custom { "ssl-${web_domain}":
        content => template('dlrn/custom_vhost_443.erb'),
        require => Letsencrypt::Certonly[$web_domain],
      }
    } else {
      apache::vhost { "ssl-${web_domain}":
        port                 => 443,
        default_vhost        => true,
        override             => 'FileInfo',
        docroot              => '/var/www/html',
        custom_fragment      => 'AddType text/plain yaml yml',
        servername           => 'default',
        ssl                  => true,
        ssl_cert             => "/etc/letsencrypt/live/${web_domain}/cert.pem",
        ssl_key              => "/etc/letsencrypt/live/${web_domain}/privkey.pem",
        ssl_chain            => "/etc/letsencrypt/live/${web_domain}/fullchain.pem",
        ssl_protocol         => 'ALL -SSLv2 -SSLv3',
        ssl_honorcipherorder => 'on',
        require              => Letsencrypt::Certonly[$web_domain],
      }
    }
    $redirect_status = 'permanent'
    $redirect_dest   = "https://${web_domain}/"
  }  else {
    $redirect_status = undef
    $redirect_dest   = undef
  }

  if $enable_api {
    include ::apache::mod::wsgi
    apache::listen { '80': }

    apache::vhost::custom { $web_domain:
      content => template('dlrn/custom_vhost_80.erb'),
    }
    -> wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/index.html':
      destination => '/var/www/html/index.html',
      cache_dir   => '/var/cache/wget',
      require     => Package['httpd'],
    }
  } else {
      apache::vhost { $web_domain:
        port            => 80,
        default_vhost   => true,
        override        => 'FileInfo',
        custom_fragment => 'AddType text/plain yaml yml',
        docroot         => '/var/www/html',
        servername      => 'default',
        redirect_status => $redirect_status,
        redirect_dest   => $redirect_dest,
      }
      -> wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/index.html':
        destination => '/var/www/html/index.html',
        cache_dir   => '/var/cache/wget',
        require     => Package['httpd'],
      }
  }
}

