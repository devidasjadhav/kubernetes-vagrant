#!/bin/bash
set -x

mkdir -p /vagrant/certificates/
pushd /vagrant/certificates/
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial  -out ca.crt -days 1000
rm -f ca.csr
popd
