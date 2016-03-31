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

end
