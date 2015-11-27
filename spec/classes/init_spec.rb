require 'spec_helper'

describe 'delorean' do

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
      it 'sets SELinux to permissive' do
        is_expected.to contain_class('selinux').with(
          :mode => 'permissive'
        )
      end

      it 'sets the default port in sshd_config' do
        is_expected.to contain_class('ssh').with(
          :server_options => { 'Port' => [22, 3300] }
        )
      end

      it 'does not enable cron or e-mail notifications' do
        is_expected.to contain_delorean__worker('centos-master').with(
          :disable_email => 'true',
          :enable_cron   => 'false',
        )
      end

      it 'does not configure lsyncd' do
        is_expected.not_to contain_concat('lsyncd.conf')
        is_expected.not_to contain_service('lsyncd')
      end
    end

    context 'with specific parameters' do
      let :params do { 
        :sshd_port              => 1234,
        :disable_email          => false,
        :enable_worker_cronjobs => true,
        :backup_server          => 'foo.example.com', }
      end

      it 'sets the proper port in sshd_config' do
        is_expected.to contain_class('ssh').with(
          :server_options => { 'Port' => [22, 1234] }
        )
      end

      it 'sets the proper worker options' do
        is_expected.to contain_delorean__worker('centos-master').with(
          :disable_email => 'false',
          :enable_cron   => 'true',
        )
      end

      it 'configures lsyncd' do
        is_expected.to contain_concat('lsyncd.conf')
        is_expected.to contain_service('lsyncd').with(
          :ensure => 'running',
          :enable => 'true',
        )
      end
    end 
end
