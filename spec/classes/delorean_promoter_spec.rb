require 'spec_helper'

describe 'delorean::promoter' do
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
    it 'creates user promoter' do
      is_expected.to contain_user('promoter').with(
        :managehome => 'true'
      ).with_before(/File\[\/home\/promoter/)
    end

    it 'creates /home/promoter' do
      is_expected.to contain_file('/home/promoter').with(
        :ensure  => 'directory',
        :owner   => 'promoter',
        :group   => 'promoter',
        :recurse => true,
      ).with_before(/File\[\/home\/promoter\/.ssh/)
    end

    it 'creates /home/promoter/.ssh' do
      is_expected.to contain_file('/home/promoter/.ssh').with(
        :ensure => 'directory',
        :owner  => 'promoter',
        :group  => 'promoter',
      ).with_before(/File\[\/home\/promoter\/.ssh\/authorized_keys/)
    end

    it 'creates /home/promoter/.ssh/authorized_keys' do
      is_expected.to contain_file('/home/promoter/.ssh/authorized_keys').with(
        :mode   => '0600',  
        :owner  => 'promoter',
        :group  => 'promoter',
      )
    end

    it 'creates /usr/local/bin/promote.sh' do
      is_expected.to contain_file('/usr/local/bin/promote.sh').with(
        :mode   => '0755',  
        :source => 'puppet:///modules/delorean/promote.sh',
      )
    end

    it 'creates the sudo entry' do
      is_expected.to contain_sudo__conf('promoter').with(
        :priority => '99',
        :content  => 'promoter ALL= NOPASSWD: /usr/local/bin/promote.sh',
        :require  => 'User[promoter]',
      )
    end
  end
end
