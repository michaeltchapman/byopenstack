node /control/ {
   $role = 'control'
   site::role{ $role: }
}

node /compute/ {
   $role = 'compute'
   site::role{ $role: }
}

define site::role
{
  package { ['kernel', 'iproute', 'iputils']:
    ensure => 'latest'
  }

  $node_classes = hiera("${name}_classes", '')
  if $node_classes {
    include $node_classes
    $s = join($node_classes, ' ')
    notice("Including node classes : ${s}")
  }
}
