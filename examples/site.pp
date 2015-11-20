class { 'delorean': 
  backup_server          => 'testbackup.example.com',
  sshd_port              => 3300,
  disable_email          => true,
  enable_worker_cronjobs => false,
}

