require 'spec_helper'

describe 'dlrn::lsyncdconfig' do
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
    :path         => '/home/centos-master',
    :sshd_port    => 1234,
    :remoteserver => 'foo.example.com',
    }
  end

  let :title do
    'centos-master'
  end 
 
  it 'configures the lsyncd.conf fragment' do
    is_expected.to contain_concat__fragment('lsyncd.conf:sync:centos-master').with(
      :target => 'lsyncd.conf',
      :order  => '200',
    ).with_content(/source=\"\/home\/centos-master\"/)
    .with_content(/target=\"foo.example.com:\/home\/centos-master\"/)
    .with_content(/rsh = \"\/usr\/bin\/ssh -p 1234 -o StrictHostKeyChecking=no\"/)
  end

end
