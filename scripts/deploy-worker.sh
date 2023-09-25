#!/bin/bash

/vagrant/scripts/08_worker.sh
/vagrant/scripts/08_1_worker.sh
/vagrant/scripts/09_cni.sh
sudo systemctl restart kubelet.service
sudo systemctl restart containerd.service
