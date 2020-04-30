require 'spec_helper'

describe 'dlrn::fail2ban' do
  let :facts do
  {   :os                        => {
          'family' => 'RedHat',
          'release' => {
              'major' => '7',
              'minor' => '1',
              'full'  => '7.6.1810',
           },
          'selinux' => {
              'enabled' => true,
          }
      },
      :osfamily               => 'RedHat',
      :operatingsystem        => 'Fedora',
      :operatingsystemrelease    => '7',
      :operatingsystemmajrelease => '7',
      :concat_basedir         => '/tmp',
      :puppetversion          => '3.7.0',
      :sudoversion            => '1.8.15',
      :processorcount         => 2 }
  end

  let :params do { 
    :sshd_port => 1234,
    }
  end

  let(:pre_condition) { 'include ::dlrn::common' }

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
