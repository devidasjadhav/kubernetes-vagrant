#!/bin/bash

WORKER_IP=192.168.199.20
LOADBALANCER=192.168.199.10
POD_CIDR=10.244.0.0/16
CLUSTER_DNS="10.200.0.0/16"

sudo apt-get update
sudo apt-get install -y socat conntrack ipset
sudo sysctl -w net.ipv4.conf.all.forwarding=1

pushd  /vagrant/bin/
chmod +x kube-proxy kubectl kubelet
sudo cp kube-proxy kubectl kubelet /usr/local/bin
popd

pushd /vagrant/certificates

cat > openssl-worker0.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker0
IP.1 = ${WORKER_IP}
EOF

openssl genrsa -out worker0.key 2048
openssl req -new -key worker0.key -subj "/CN=system:node:worker0/O=system:nodes" -out worker0.csr -config openssl-worker0.cnf
openssl x509 -req -in worker0.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker0.crt -extensions v3_req -extfile openssl-worker0.cnf -days 1000

openssl genrsa -out kube-proxy.key 2048
openssl req -new -key kube-proxy.key \
  -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr
openssl x509 -req -in kube-proxy.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-proxy.crt -days 1000

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=worker0.kubeconfig

  kubectl config set-credentials system:node:worker0 \
    --client-certificate=/var/lib/kubernetes/pki/worker0.crt \
    --client-key=/var/lib/kubernetes/pki/worker0.key \
    --kubeconfig=worker0.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:worker0 \
    --kubeconfig=worker0.kubeconfig

  kubectl config use-context default --kubeconfig=worker0.kubeconfig
}
{
  sudo mkdir -p /var/lib/kubernetes/pki/
  sudo mkdir -p /var/lib/kubelet/
  sudo mkdir -p /var/lib/kube-proxy/
  sudo cp ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubernetes/pki/
  sudo cp ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubelet.kubeconfig
  sudo cp ca.crt /var/lib/kubernetes/pki/
  sudo cp kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki/
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
  sudo chown root:root /var/lib/kubelet/*
  sudo chmod 600 /var/lib/kubelet/*
}


cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /var/lib/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
clusterDomain: cluster.local
clusterDNS:
  - ${CLUSTER_DNS}
resolvConf: /run/systemd/resolve/resolv.conf
runtimeRequestTimeout: "15m"
tlsCertFile: /var/lib/kubernetes/pki/${HOSTNAME}.crt
tlsPrivateKeyFile: /var/lib/kubernetes/pki/${HOSTNAME}.key
registerNode: true
EOF

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
    --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/
popd

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kube-proxy.kubeconfig"
mode: "iptables"
clusterCIDR: ${POD_CIDR}
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}
