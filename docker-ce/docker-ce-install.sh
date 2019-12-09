#!/bin/bash
#mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
#
#curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel.repo
yum install epel-release -y
yum install -y yum-utils

yum install wget net-tools telnet tree nmap sysstat lrzsz dos2unix bind-utils -y

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum install -y docker-ce

mkdir -p /etc/docker

mkdir -p /data/docker

localIP=$(ip addr|grep eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "add:")

localip=${localIP%/*}

backip=$(echo $localip|awk -F. '{ print $3"."$4 }')
echo '{
  "graph": "/data/docker",
  "storage-driver": "overlay2",
  "insecure-registries": ["registry.access.redhat.com", "quay.io", "harbor.od.com"],
  "registry-mirrors": ["https://q2gr04ke.mirror.aliyuncs.com"],
  "bip": "172.'$backip'.1/24",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true
}' > /etc/docker/daemon.json

systemctl start docker

systemctl enable docker
#systemctl restart docker
