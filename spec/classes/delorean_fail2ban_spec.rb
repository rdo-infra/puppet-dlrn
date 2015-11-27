require 'spec_helper'

describe 'delorean::fail2ban' do
  let :facts do
  {   :osfamily               => 'RedHat',
      :operatingsystem        => 'Fedora',
      :operatingsystemrelease => '24',
      :concat_basedir         => '/tmp',
      :puppetversion          => '3.7.0',
      :sudoversion            => '1.8.15',
      :processorcount         => 2 }
  end

  let :params do { 
    :sshd_port => 1234,
    }
  end


  context 'with specific parameters' do
    it 'installs the right packages' do
      is_expected.to contain_package('fail2ban').with( :ensure => 'installed')
      is_expected.to contain_package('fail2ban-systemd').with( :ensure => 'installed')
    end

    it 'configures fail2ban sshd info' do
      is_expected.to contain_file('/etc/fail2ban/jail.d/01-sshd.conf').with(
        :content => "[sshd]\nenabled = true\nport = 1234",
        :require => 'Package[fail2ban]',
      ).with_before(/Service\[fail2ban\]/)
    end

    it 'enables fail2ban service' do
      is_expected.to contain_service('fail2ban').with(
        :ensure  => 'running',
        :enable  => 'true',
        :require => 'Service[firewalld]',
      )
    end
  end

end
