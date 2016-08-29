require 'spec_helper'
require 'hiera'

describe 'dlrn::web' do
  let :facts do
  {   :kernel                    => 'Linux',
      :osfamily                  => 'RedHat',
      :operatingsystem           => 'Fedora',
      :operatingsystemrelease    => '24',
      :operatingsystemmajrelease => '24',
      :concat_basedir            => '/tmp',
      :path                      => '/bin:/usr/bin:/usr/sbin',
      :puppetversion             => '3.7.0',
      :selinux_current_mode      => 'enforcing',
      :sudoversion               => '1.8.15',
      :processorcount            => 2 }
  end

  let(:hiera_config) { 'spec/fixtures/hiera.yaml' }
  hiera = Hiera.new(:config => 'spec/fixtures/hiera.yaml')

  context 'with default parameters' do
    it 'installs httpd package' do
      is_expected.to contain_package('httpd').with( :ensure => 'installed')
      is_expected.not_to contain_package('mod_ssl')
    end

    it 'enables httpd service' do
      is_expected.to contain_service('httpd').with(
        :ensure  => 'running',
        :enable  => 'true',
      )
    end

    it 'enables http port' do
      is_expected.to contain_apache__vhost('dummy.example.com').with(:port => 80)
    end

    it 'creates /var/www/html/images' do
      is_expected.to contain_file('/var/www/html/images').with(
        :ensure  => 'directory',
        :mode    => '0755',
        :require => 'Package[httpd]',
      ).with_before(/Wget::Fetch\[https\:\/\/raw.githubusercontent.com\/redhat-openstack\/trunk.rdoproject.org\/master\/images\/rdo-logo-white.png\]/)
    end

    it 'fetches the rdo logo' do
      is_expected.to contain_wget__fetch('https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/images/rdo-logo-white.png').with(
        :destination => '/var/www/html/images/rdo-logo-white.png',
        :cache_dir   => '/var/cache/wget',
        :require     => 'Package[httpd]',
      )
    end

    it 'fetches the index page' do
      is_expected.to contain_wget__fetch('https://raw.githubusercontent.com/redhat-openstack/trunk.rdoproject.org/master/index.html').with(
        :destination => '/var/www/html/index.html',
        :cache_dir   => '/var/cache/wget',
        :require     => 'Package[httpd]',
      )
    end

    it 'creates the update-web-index cron job' do
      is_expected.to contain_file('/usr/local/bin/update-web-index.sh').with(
        :ensure => 'present',
        :mode   => '0755',
        :source => 'puppet:///modules/dlrn/update-web-index.sh',
      ).with_before(/Cron\[update-web-index\]/)
      is_expected.to contain_cron('update-web-index').with(
        :command => '/usr/local/bin/update-web-index.sh > /dev/null',
        :user    => 'root',
        :hour    => '3',
        :minute  => '0',
      )
    end

    it 'does not create ssl vhost' do
      is_expected.not_to contain_apache__vhost('ssl-dummy.example.com').with(:port => 443)
    end

    it 'does not create ssl certificates' do
      is_expected.not_to contain_class('letsencrypt')
      is_expected.not_to contain_letsencrypt__certonly('dummy.example.com')
    end
  end

  context 'with enable_https enabled' do
    let :params do { 
      :enable_https => true
    }
    end

    it 'installs mod_ssl package' do
      is_expected.to contain_package('mod_ssl')
    end

    it 'does create ssl vhost' do
      is_expected.to contain_apache__vhost('ssl-dummy.example.com').with(
        :port                 => 443,
        :default_vhost        => true,
        :override             => 'FileInfo',
        :docroot              => '/var/www/html',
        :servername           => 'default',
        :ssl_cert             => '/etc/letsencrypt/live/dummy.example.com/cert.pem',
        :ssl_key              => '/etc/letsencrypt/live/dummy.example.com/privkey.pem',
        :ssl_chain            => '/etc/letsencrypt/live/dummy.example.com/fullchain.pem',
        :ssl                  => true,
        :ssl_protocol         => 'ALL -SSLv2 -SSLv3',
        :ssl_honorcipherorder => 'on'
      )
    end

    it 'does create ssl certificates' do
      is_expected.to contain_class('letsencrypt').with(
        :configure_epel => false,
        :email          => 'dummy@example.com',
        :package_name   => 'certbot',
      )
      is_expected.to contain_letsencrypt__certonly('dummy.example.com').with(
        :plugin               => 'webroot',
        :webroot_paths        => [ '/var/www/html' ],
        :domains              => [ 'dummy.example.com' ],
        :manage_cron          => true,
        :cron_success_command => '/bin/systemctl reload httpd',
      )
    end
  end

end
