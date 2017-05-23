require 'spec_helper'

describe 'dlrn::common' do

    let :facts do
    {   :osfamily                  => 'RedHat',
        :operatingsystem           => 'Fedora',
        :operatingsystemrelease    => '24',
        :operatingsystemmajrelease => '24',
        :concat_basedir            => '/tmp',
        :puppetversion             => '3.7.0',
        :selinux                   => true,
        :selinux_current_mode      => 'permissive',
        :sshed25519key             => '',
        :sshecdsakey               => '',
        :sshdsakey                 => '',
        :sshrsakey                 => '',
        :sudoversion               => '1.8.15',
        :blockdevices              => 'vda,vdb',
        :processorcount            => 2 }
    end

    context 'with default parameters' do
      it 'sets SELinux to enforcing' do
        is_expected.to contain_class('selinux').with(
          :mode => 'enforcing'
        )
      end

      it 'sets the required selinux booleans' do
        is_expected.to contain_selboolean('httpd_read_user_content').with(
          :persistent => 'true',
          :value      => 'on',
        )

        is_expected.to contain_selboolean('httpd_enable_homedirs').with(
          :persistent => 'true',
          :value      => 'on',
        )
      end

      it 'sets the default port in sshd_config' do
        is_expected.to contain_class('ssh').with(
          :server_options => { 'Port' => [22, 3300] }
        )
      end

      it 'creates vgdelorean' do
        is_expected.to contain_volume_group('vgdelorean')
        is_expected.to contain_physical_volume('/dev/vdb')
      end

      it 'does not create a mock site-defaults.cfg file' do
        is_expected.not_to contain_file('/etc/mock/site-defaults.cfg')
      end

      it 'creates required firewall rules' do
       is_expected.to contain_firewalld_service('Allow SSH').with(
         :service => 'ssh',
         :zone    => 'public',
       )
       is_expected.to contain_firewalld_service('Allow HTTP').with(
         :service => 'http',
         :zone    => 'public',
       )
       is_expected.to contain_firewalld_port('Allow custom SSH port').with(
         :port     => 3300,
         :zone     => 'public',
         :protocol => 'tcp',
       )
      end

      it 'does not create firewall rule for https' do
       is_expected.not_to contain_firewalld_service('Allow HTTPS').with(
         :service => 'https',
         :zone    => 'public',
       )
      end
    end

    context 'with specific parameters' do
      let :params do { 
        :sshd_port         => 1234,
        :enable_https      => true
      }
      end

      before :each do
        facts.merge!(:blockdevices => 'vda')
      end

      it 'sets the proper port in sshd_config' do
        is_expected.to contain_class('ssh').with(
          :server_options => { 'Port' => [22, 1234] }
        )
      end

      it 'does not create vgdelorean' do
        is_expected.not_to contain_volume_group('vgdelorean')
        is_expected.not_to contain_physical_volume('/dev/vdb')
      end

      it 'creates firewall rule for https' do
       is_expected.to contain_firewalld_service('Allow HTTPS').with(
         :service => 'https',
         :zone    => 'public',
       )
      end
   end 
end
