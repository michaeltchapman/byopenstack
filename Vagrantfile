# -*- mode: ruby -*-
# vi: set ft=ruby :
def configure(config)
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
  end

  config.vm.provision :shell do |shell|
    shell.inline = 'bash /vagrant/provision/bootstrap.sh'
  end

  config.vm.provision :puppet do |puppet|
    puppet.module_path = "modules"
    puppet.manifest_file = "site.pp"
    puppet.hiera_config_path = "hiera/hiera.yaml"
    puppet.working_directory = "/vagrant/hiera/data"
  end
end

Vagrant.configure("2") do |config|

  config.vm.define "control" do |control|
    control.vm.box = "centos64"
    control.vm.hostname = "control"
    control.vm.network "private_network", :ip => "192.168.242.10"
    control.vm.network "private_network", :ip => "10.2.3.10"
    control.vm.network "private_network", :ip => "10.3.3.10"
    configure(control)
  end

  config.vm.define "compute" do |compute|
    compute.vm.box = "centos64"
    compute.vm.hostname = "compute"
    compute.vm.network "private_network", :ip => "192.168.242.21"
    compute.vm.network "private_network", :ip => "10.2.3.21"
    compute.vm.network "private_network", :ip => "10.3.3.21"
    configure(compute)
  end

end
