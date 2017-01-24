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

class dlrn::web(
  $web_domain,
  $enable_https = false,
  $cert_mail = undef,
){

  class { 'apache':
    default_vhost => false,
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
    }->
    apache::vhost { "ssl-${web_domain}":
      port                 => 443,
      default_vhost        => true,
      override             => 'FileInfo',
      docroot              => '/var/www/html',
      servername           => 'default',
      ssl                  => true,
      ssl_cert             => "/etc/letsencrypt/live/${web_domain}/cert.pem",
      ssl_key              => "/etc/letsencrypt/live/${web_domain}/privkey.pem",
      ssl_chain            => "/etc/letsencrypt/live/${web_domain}/fullchain.pem",
      ssl_protocol         => 'ALL -SSLv2 -SSLv3',
      ssl_honorcipherorder => 'on',
    }
    $redirect_status = 'permanent'
    $redirect_dest   = "https://${web_domain}"
  }  else {
    $redirect_status = undef
    $redirect_dest   = undef
  }


  apache::vhost { $web_domain:
    port            => 80,
    default_vhost   => true,
    override        => 'FileInfo',
    docroot         => '/var/www/html',
    servername      => 'default',
    redirect_status => $redirect_status,
    redirect_dest   => $redirect_dest,
  } ->
  wget::fetch { 'https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/index.html':
    destination => '/var/www/html/index.html',
    cache_dir   => '/var/cache/wget',
    require     => Package['httpd'],
  }
}

