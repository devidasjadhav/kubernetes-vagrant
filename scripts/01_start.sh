#!/bin/bash

readonly k8s_version="v1.28.1"
readonly etcd_version="v3.5.9"
readonly cfssl_version="1.6.4"

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

mkdir -p /vagrant/bin
pushd /vagrant/bin
wget --continue --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kubectl" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kube-proxy" \
  "https://storage.googleapis.com/kubernetes-release/release/${k8s_version}/bin/linux/amd64/kubelet" \
  "https://github.com/coreos/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
popd
