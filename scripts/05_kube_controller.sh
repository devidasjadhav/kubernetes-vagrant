#!/bin/bash
#
SERVER_IP=192.168.199.10

pushd /vagrant/bin/
chmod +x kubectl
sudo cp kubectl /usr/local/bin/
chmod +x kube-controller-manager
sudo cp kube-controller-manager /usr/local/bin
popd

pushd /vagrant/certificates
openssl genrsa -out kube-controller-manager.key 2048
openssl req -new -key kube-controller-manager.key -subj "/CN=system:kube-controller-manager" -out kube-controller-manager.csr
openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000

kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.crt \
    --client-key=kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

sudo mkdir /var/lib/kubernetes
cp kube-controller-manager.crt kube-controller-manager.key kube-controller-manager.kubeconfig ca.key /var/lib/kubernetes/
popd

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
--bind-address=0.0.0.0 \\
--service-cluster-ip-range=10.32.0.0/24 \\
--cluster-cidr=10.200.0.0/16 \\
--kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
--authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
--authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
--leader-elect=true \\
--cluster-signing-cert-file=/var/lib/kubernetes/ca.crt \\
--cluster-signing-key-file=/var/lib/kubernetes/ca.key \\
--root-ca-file=/var/lib/kubernetes/ca.crt \\
--service-account-private-key-file=/var/lib/kubernetes/service-account.key \\
--use-service-account-credentials=true \\
--v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl start kube-controller-manager
systemctl enable kube-controller-manager
