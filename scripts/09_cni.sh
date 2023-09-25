#!/bin/bash

pushd /vagrant/bin
wget --continue --show-progress --https-only --timestamping \
 "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -xvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin
popd

sudo mkdir -p /run/systemd/resolve/
sudo ln -s /etc/resolv.conf /run/systemd/resolve/resolv.conf

sudo sed -i 's/SystemdCgroup = true/SystemdCgroup = false/g' /etc/containerd/config.toml
