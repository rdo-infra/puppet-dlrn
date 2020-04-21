require 'spec_helper'
require 'hiera'

describe 'dlrn::web' do
  let :facts do
  {   :kernel                    => 'Linux',
      :os                        => {
          'family' => 'RedHat',
          'release' => {
              'major' => '7',
              'minor' => '1',
              'full'  => '7.6.1810',
           }
      },
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

    it "should check if python-home is set" do
      is_expected.to contain_apache__vhost__custom('dummy.example.com').with_content(
        /^  WSGIDaemonProcess dlrn-centos-newton python-home=\/home\/centos-newton\/.venv/
      )
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
        :package_name   => 'certbot',
        :config         => {
            'email'  => 'dummy@example.com',
            'server' => 'https://acme-v02.api.letsencrypt.org/directory',
        }

      )
      is_expected.to contain_letsencrypt__certonly('dummy.example.com').with(
        :plugin        => 'webroot',
        :webroot_paths => [ '/var/www/html' ],
        :domains       => [ 'dummy.example.com' ],
        :manage_cron   => false,
      )
      is_expected.to contain_cron('Renew SSL cert for dummy.example.com').with(
        :weekday     => '0',
        :hour        => '3',
        :minute      => '15',
        :command     => 'certbot --agree-tos certonly -a webroot --keep-until-expiring --webroot-path /var/www/html -d dummy.example.com && (/bin/systemctl reload httpd)',
        :environment => 'VENV_PATH=/opt/letsencrypt/.venv',
        :user        => 'root',
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

    it "should check if python-home is set for https" do
      is_expected.to contain_apache__vhost__custom('dummy.example.com').with_content(
        /^  WSGIDaemonProcess ssl-dlrn-centos-newton python-home=\/home\/centos-newton\/.venv/
      )
    end
  end
end
