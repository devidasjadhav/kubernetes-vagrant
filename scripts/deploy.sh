#!/bin/bash
#

/vagrant/scripts/01_start.sh
/vagrant/scripts/02_createCerts.sh
/vagrant/scripts/03_etcd.sh
/vagrant/scripts/04_api_server.sh
/vagrant/scripts/05_kube_controller.sh
/vagrant/scripts/06_kube_schedular.sh
/vagrant/scripts/07_cluster.sh
