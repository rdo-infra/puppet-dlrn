require 'spec_helper'
require 'hiera'

describe 'dlrn' do

    let :facts do
    {   :kernel                    => 'Linux',
        :osfamily                  => 'RedHat',
        :operatingsystem           => 'CentOS',
        :operatingsystemrelease    => '7',
        :operatingsystemmajrelease => '7',
        :os                        => {
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
        :concat_basedir            => '/tmp',
        :puppetversion             => '5.5.10',
        :selinux                   => true,
        :selinux_current_mode      => 'enforcing',
        :sshed25519key             => '',
        :sshecdsakey               => '',
        :sshdsakey                 => '',
        :sshrsakey                 => '',
        :sudoversion               => '1.8.15',
        :blockdevices              => 'vda,vdb',
        :processorcount            => 2 }
    end

    let(:hiera_config) { 'spec/fixtures/hiera.yaml' }
    hiera = Hiera.new(:config => 'spec/fixtures/hiera.yaml')

    context 'with default parameters' do
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
        is_expected.to contain_dlrn__worker('centos-train').with(
          :name           => 'centos-train',
          :distro         => 'centos7',
          :target         => 'centos-train',
          :distgit_branch => 'train-rdo',
          :distro_branch  => 'stable/train',
          :disable_email  => :true,
          :enable_cron    => :false,
          :symlinks       => ['/var/www/html/centos7-train', '/var/www/html/train/centos7'],
          :release        => 'train'
        )
      end

      it 'ensures dlrn::common is executed before any worker' do
        is_expected.to contain_class('dlrn::common').with_before(/Dlrn::Worker\[.+\]/)
      end
    end

    context 'with specific parameters' do
      let :params do {
        :sshd_port     => 1234
      }
      end

      it 'sets sshd options for dlrn::common' do
        is_expected.to contain_class('dlrn::common').with(
          :sshd_port         => 1234,
        )
      end
    end
end
