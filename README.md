# puppet-delorean

This is a Puppet module aimed at setting up a new Delorean instance from
scratch.

**Note:** this is still work in progress. It is lacking documentation, spec
tests and proper installation. For now, put this under /etc/puppet/modules
and run the following commands to install the modules it depends on:

puppet module install spiette-selinux
puppet module install blentz-selinux_types
puppet module install saz-ssh
puppet module install saz-sudo
puppet module install puppetlabs-vcsrepo
puppet module install puppetlabs-lvm
puppet module install ceritsc-yum
puppet module install crayfishx-firewalld
puppet module install maestrodev-wget

