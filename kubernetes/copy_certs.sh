#!/bin/bash

ln -s $PWD/kubernetes-v* /opt/kubernetes

mkdir -p /opt/kubernetes/server/bin/certs

cp -r ../certs/pem/*.pem /opt/kubernetes/server/bin/certs

