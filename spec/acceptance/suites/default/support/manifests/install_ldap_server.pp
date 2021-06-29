# NOTE: The LDAP server configuration configuration largely handled from hiera

if $facts['os']['release']['major'] == '7' {
  class{'simp_openldap': is_server => true }
}
else {
  include 'simp_ds389::instances::accounts'
}

include 'svckill'
include 'iptables'
iptables::listen::tcp_stateful { 'ssh':
  dports       => 22,
  trusted_nets => ['any'],
}
