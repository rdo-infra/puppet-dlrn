require 'spec_helper'

describe 'delorean::common' do

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
    end

    context 'with specific parameters' do
      let :params do { 
        :sshd_port              => 1234,
      }
      end

      it 'sets the proper port in sshd_config' do
        is_expected.to contain_class('ssh').with(
          :server_options => { 'Port' => [22, 1234] }
        )
      end
    end 
end
