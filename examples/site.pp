class { 'dlrn': 
#  backup_server          => 'testbackup.example.com',
  sshd_port              => 3300,
  mock_tmpfs_enable      => false,
  server_type            => 'primary',
  enable_https           => false,
}

