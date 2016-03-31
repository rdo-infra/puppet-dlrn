require 'spec_helper'
require 'hiera'

describe 'dlrn' do

    let :facts do
    {   :osfamily               => 'RedHat',
        :operatingsystem        => 'Fedora',
        :operatingsystemrelease => '24',
        :concat_basedir         => '/tmp',
        :puppetversion          => '3.7.0',
        :sudoversion            => '1.8.15',
        :blockdevices           => 'vda,vdb',
        :processorcount         => 2 }
    end

    let(:hiera_config) { 'spec/fixtures/hiera.yaml' }
    hiera = Hiera.new(:config => 'spec/fixtures/hiera.yaml')

    context 'with default parameters' do
      it 'does not configure lsyncd' do
        is_expected.not_to contain_concat('lsyncd.conf')
        is_expected.not_to contain_service('lsyncd')
      end

      it 'creates dlrn workers based on Hiera template' do
        is_expected.to contain_dlrn__worker('centos-master').with(
          :name           => 'centos-master',
          :distro         => 'centos7',
          :target         => 'centos',
          :distgit_branch => 'rpm-master',
          :distro_branch  => 'master',
          :disable_email  => :true,
          :enable_cron    => :false,
          :symlinks       => ['/var/www/html/centos7', '/var/www/html/centos70', '/var/www/html/centos7-master']
        )
        is_expected.to contain_dlrn__worker('centos-liberty').with(
          :name           => 'centos-liberty',
          :distro         => 'centos7',
          :target         => 'centos-liberty',
          :distgit_branch => 'rpm-liberty',
          :distro_branch  => 'stable/liberty',
          :disable_email  => :true,
          :enable_cron    => :false,
          :symlinks       => ['/var/www/html/centos7-liberty', '/var/www/html/liberty/centos7'],
          :release        => 'liberty'
        )
      end

      it 'ensures dlrn::common is executed before any worker' do
        is_expected.to contain_class('dlrn::common').with_before(/Dlrn::Worker\[.+\]/)
      end
    end

    context 'with specific parameters' do
      let :params do { 
        :sshd_port     => 1234,
        :backup_server => 'foo.example.com' }
      end

      it 'sets sshd options for dlrn::common' do
        is_expected.to contain_class('dlrn::common').with(
          :sshd_port => 1234,
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
