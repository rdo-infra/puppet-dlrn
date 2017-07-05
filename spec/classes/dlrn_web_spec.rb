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
      is_expected.to contain_apache__vhost('dummy.example.com').with(
        :port            => 80,
        :redirect_status => nil)
    end

    it 'creates the index page' do
      is_expected.to contain_file('/var/www/html/index.html').with(
        :ensure => 'present',
        :mode   => '0644',
        :source => 'puppet:///modules/dlrn/homepage.html',
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

  context 'with api enabled' do
    let :params do {
      :enable_api  => true,
      :api_workers => ['centos-ocata', 'centos-newton'],
    }
    end

    it 'does not create the default vhost' do
      is_expected.not_to contain_apache__vhost('dummy.example.com')
    end

    it 'listens on port 80' do
      is_expected.to contain_apache__listen('80')
    end

    it 'uses the custom vhost template' do
      is_expected.to contain_apache__vhost__custom('dummy.example.com')
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

    it 'creates redirection from http to https' do
      is_expected.to contain_apache__vhost('dummy.example.com').with(
        :port            => 80,
        :redirect_status => 'permanent',
        :redirect_dest   => 'https://dummy.example.com/')
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

  context 'with enable_https and enable_api' do
    let :params do {
      :enable_https => true,
      :enable_api  => true,
      :api_workers => ['centos-ocata', 'centos-newton'],
    }
    end

    it 'does not create the ssl vhost' do
      is_expected.not_to contain_apache__vhost('ssl-dummy.example.com')
    end

    it 'listens on port 443' do
      is_expected.to contain_apache__listen('443')
    end

    it 'uses the custom vhost template' do
      is_expected.to contain_apache__vhost__custom('ssl-dummy.example.com')
    end
  end
end
