node 'worker0.localdomain' {
  # Install Docker Compose
  class { 'docker::compose':
    ensure  => present,
    version => '2.29.7-1~ubuntu.22.04~jammy',
  }

  # Clone the Git repository
  vcsrepo { '/opt/mire':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/2BAD/mire.git',
    revision => 'master',
  }

  # Ensure proper permissions for the directory
  file { '/opt/mire':
    ensure  => 'directory',
    owner   => 'vagrant',
    group   => 'vagrant',
    recurse => true,
    require => Vcsrepo['/opt/mire'],
  }

  # Install build-essential and other required libraries
  package { [
    'build-essential',
    'libcairo2-dev',
    'libpango1.0-dev',
    'libjpeg-dev',
    'libgif-dev',
    'librsvg2-dev',
  ]:
    ensure => installed,
    before => Exec['add-nodesource-repo'],
  }

  # Add NodeSource repository for Node.js 22.x
  exec { 'add-nodesource-repo':
    command => 'curl -fsSL https://deb.nodesource.com/setup_22.x | bash -',
    path    => ['/usr/bin', '/bin'],
    creates => '/etc/apt/sources.list.d/nodesource.list',
    before  => Package['nodejs'],
  }

  # Install Node.js
  package { 'nodejs':
    ensure  => installed,
    require => Exec['add-nodesource-repo'],
    before  => Exec['install-canvas'],
  }

  # Install the canvas package using npm
  exec { 'install-canvas':
    command => 'npm install canvas@next --verbose',
    cwd     => '/opt/mire',
    path    => ['/usr/bin', '/bin'],
    require => Package['nodejs'],
    before  => File['/opt/mire/docker/.env'],
  }

  # Rename the .env.example file
  file { '/opt/mire/docker/.env':
    ensure  => file,
    source  => '/opt/mire/docker/.env.example',
    require => Vcsrepo['/opt/mire'],
  }

  # Run docker compose up
  exec { 'docker-compose-up':
    command => 'docker compose up -d',
    cwd     => '/opt/mire/docker',
    path    => ['/usr/bin', '/bin'],
    require => [
      Class['docker::service'], # Depend on the service class from the Docker module
      File['/opt/mire/docker/.env'],
    ],
  }
}
