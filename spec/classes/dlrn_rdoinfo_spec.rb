require 'spec_helper'

describe 'dlrn::rdoinfo' do
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
    it 'creates user rdoinfo' do
      is_expected.to contain_user('rdoinfo').with(
        :managehome => 'true',
        :groups     => ['users','mock'],
      ).with_before(/File\[\/home\/rdoinfo/)
    end

    it 'creates /home/rdoinfo' do
      is_expected.to contain_file('/home/rdoinfo').with(
        :ensure => 'directory',
        :owner  => 'rdoinfo',
        :mode   => '0755',
      ).with_before(/Exec\[ensure home contents belong to rdoinfo\]/)
    end

    it 'clones the rdoinfo git repo' do
      is_expected.to contain_vcsrepo('/home/rdoinfo/rdoinfo').with(
        :provider => 'git',
        :source   => 'https://github.com/redhat-openstack/rdoinfo',
        :user     => 'rdoinfo',
      )
    end

    it 'creates /usr/local/bin/rdoinfo-update.sh' do
      is_expected.to contain_file('/usr/local/bin/rdoinfo-update.sh').with(
        :mode   => '0755',  
        :source => 'puppet:///modules/dlrn/rdoinfo-update.sh',
      )
    end

    it 'creates an hourly cron job for rdoinfo-update' do
      is_expected.to contain_cron('rdoinfo').with(
        :command => '/usr/local/bin/rdoinfo-update.sh',
        :user    => 'rdoinfo',
        :hour    => '*',
        :minute  => '7',
      )
    end

  end
end
