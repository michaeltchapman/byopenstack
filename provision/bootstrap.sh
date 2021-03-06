#!/usr/bin/env bash

network=eth1
domain='domain.name'
proxy="${proxy:-}"

while getopts "h?p:" opt; do
    case "$opt" in
    h|\?)
        echo "Not helpful help message"
        exit 0
        ;;
    p)  proxy=$OPTARG
        ;;
    esac
done

# Set either yum or apt to use an http proxy.
if [ $proxy ] ; then
    echo 'setting proxy'
    export http_proxy=$proxy

    if [ -f /etc/redhat-release ] ; then
        if [ ! $(cat /etc/yum.conf | grep '^proxy=') ] ; then
            echo "proxy=$proxy" >> /etc/yum.conf
        fi
    elif [ -f /etc/debian_version ] ; then
        if [ ! -f /etc/apt/apt.conf.d/01apt-cacher-ng-proxy ] ; then
            echo "Acquire::http { Proxy \"$proxy\"; };" > /etc/apt/apt.conf.d/01apt-cacher-ng-proxy;
            apt-get update -q
        fi
    else
        echo "OS not detected! Weirdness inbound!"
    fi
else
    echo 'not setting proxy'
fi

hash puppet 2>/dev/null || {
      puppet_version=0
}

if [ "${puppet_version}" != '0' ] ; then
  puppet_version=$(puppet --version)
fi

if [ "${puppet_version}" != "${desired_puppet}" ] ; then
  echo '[puppetlabs]' > /etc/yum.repos.d/puppetlabs.repo
  echo "name=\"Puppetlabs Yum Repo\"" >> /etc/yum.repos.d/puppetlabs.repo
  echo "baseurl=\"http://yum.puppetlabs.com/el/\$releasever/products/\$basearch/\"" >> /etc/yum.repos.d/puppetlabs.repo
  echo 'enabled=1' >> /etc/yum.repos.d/puppetlabs.repo
  echo 'gpgcheck=1' >> /etc/yum.repos.d/puppetlabs.repo
  echo 'gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs' >> /etc/yum.repos.d/puppetlabs.repo

  yum install puppet hiera -y -q
fi

# Ensure puppet isn't going to sign a cert with the wrong time or
# name
ipaddress=$(facter ipaddress_$network)
fqdn=$(facter hostname).${domain}
facter_fqdn=$(facter fqdn)
# If it doesn't match what puppet will be setting for fqdn, just redo
# to the point where we can see the master and have fqdn
if [ "${facter_fqdn}" != "${fqdn}" ] ; then
  if ! grep -q "$ipaddress\s$fqdn" /etc/hosts ; then
    echo 'configuring /etc/hosts for fqdn'
    if [ -f /etc/redhat-release ] ; then
        echo "$ipaddress $fqdn $(hostname)" > /etc/hosts
        echo "127.0.0.1       localhost       localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts
        echo "::1     localhost       localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
        echo "$(hiera build_server_ip) $(hiera build_server_name) $(hiera build_server_name).$(hiera domain_name)" >> /etc/hosts
    elif [ -f /etc/debian_version ] ; then
        echo "$ipaddress $fqdn $(hostname)" > /etc/hosts
        echo "127.0.0.1       localhost       localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts
        echo "::1     localhost       localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
        echo "$(hiera build_server_ip) $(hiera build_server_name) $(hiera build_server_name).$(hiera domain_name)" >> /etc/hosts
    fi
  fi
fi

cat > /etc/sysconfig/iptables<<EOF
# Firewall configuration written by system-config-firewall
# Manual customization of this file is not recommended.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
COMMIT
EOF

