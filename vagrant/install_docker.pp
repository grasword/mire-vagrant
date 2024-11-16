node 'worker0.localdomain' {
  class {'docker::compose':
    ensure  => present,
    version => '2.29.7-1~ubuntu.22.04~jammy',
  }
}
