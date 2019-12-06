#!/bin/bash

cfssl gencert -initca ca-csr.json | cfssljson -bare ./pem/ca

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json | cfssljson -bare ./pem/etcd-peer

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssljson -bare ./pem/client

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare ./pem/apiserver

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json | cfssljson -bare ./pem/kubelet

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=client kube-proxy-csr.json | cfssljson -bare ./pem/kube-proxy-client

sleep 1
