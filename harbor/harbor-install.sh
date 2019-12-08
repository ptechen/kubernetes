#!/bin/bash

# /opt/harbor/harbor.yml
# hostname: harbor.od.com
# http:
#   port: 180
# data_volume: /data/harbor
# location: /data/harbor/logs
tar xf harbor-offline-installer-v1.8.5.tgz

ln -s $PWD/harbor /opt/harbor

mkdir -p /data/harbor/logs

yum install docker-compose -y

sh /opt/harbor/install.sh

yum install -y nginx

echo 'server {
    listen       80;
    server_name  harbor.od.com;
    client_max_body_size 1000m;
    location / {
        proxy_pass http://127.0.0.1:180;
    }
}' > /etc/nginx/conf.d/harbor.od.com.conf

systemctl start nginx

systemctl enable nginx
