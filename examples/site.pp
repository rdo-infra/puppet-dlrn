class { 'dlrn':
  sshd_port         => 3300,
  mock_tmpfs_enable => false,
  server_type       => 'primary',
  enable_https      => false,
}

