require 'spec_helper'

describe 'dlrn::web' do
  let :facts do
  {   :osfamily               => 'RedHat',
      :operatingsystem        => 'Fedora',
      :operatingsystemrelease => '24',
      :concat_basedir         => '/tmp',
      :puppetversion          => '3.7.0',
      :sudoversion            => '1.8.15',
      :processorcount         => 2 }
  end

  context 'with default parameters' do
    let :params do {
      :enable_https => true
      }
    end

    it 'sets permissions to ssl files' do
      is_expected.to contain_file('/etc/pki/tls/certs/trunk_rdoproject_org.crt')
      .with(
        :owner => 'root',
        :group => 'root',
        :mode  => '0600',
      ) 
      is_expected.to contain_file('/etc/pki/tls/certs/DigiCertCA.crt')
      .with(
        :owner => 'root',
        :group => 'root',
        :mode  => '0600',
      ) 
      is_expected.to contain_file('/etc/pki/tls/private/trunk.rdoproject.org.key')
      .with(
        :owner => 'root',
        :group => 'root',
        :mode  => '0600',
      ) 
    end

    it 'installs httpd packages' do
      is_expected.to contain_package('httpd').with( :ensure => 'installed')
      is_expected.to contain_package('mod_ssl').with( :ensure => 'present')
    end

    it 'enables httpd service' do
      is_expected.to contain_service('httpd').with(
        :ensure  => 'running',
        :enable  => 'true',
      )
    end

    it 'enables http and https port' do
      is_expected.to contain_apache__vhost('trunk.rdoproject.org').with(:port => 80)
      is_expected.to contain_apache__vhost('ssl-trunk.rdoproject.org').with(:port => 443)
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
        :command => '/usr/local/bin/update-web-index.sh',
        :user    => 'root',
        :hour    => '3',
        :minute  => '0',
      )
    end
  end

  context 'with enable_https disabled' do
    let :params do {
      :enable_https => false
      }
    end

    it 'enables http and https port' do
      is_expected.to contain_apache__vhost('trunk.rdoproject.org').with(:port => 80)
      is_expected.not_to contain_apache__vhost('ssl-trunk.rdoproject.org').with(:port => 443)
    end
  end

end
