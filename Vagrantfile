# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Kubernetes Master Server
  #config.vm.provision "shell", path: "base.sh"

  config.vm.define "kubemaster" do |node|
  
    node.vm.box               = "debian/bookworm64"
    node.vm.hostname          = "kubemaster"

    node.vm.network "private_network", ip: "192.168.199.10"
  
    node.vm.provider :virtualbox do |v|
      v.name    = "kubemaster"
      v.memory  = 1024
      v.cpus    =  1
    end
    node.vm.provision "shell", path: "scripts/deploy.sh"
  end

  # Kubernetes Worker Node

    config.vm.define "worker0" do |node|

      node.vm.box               = "debian/bookworm64"
      node.vm.hostname          = "worker0"

    node.vm.network "private_network", ip: "192.168.199.20"

    node.vm.provider :virtualbox do |v|
      v.name    = "worker0"
      v.memory  = 2048
      v.cpus    = 2
    end
    node.vm.provision "shell", path: "scripts/deploy-worker.sh"
    end

end
