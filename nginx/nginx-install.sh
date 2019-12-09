#!/bin/bash

yum install nginx -y

echo '
stream {
    upstream kube-apiserver {
        server 10.4.7.127:6443     max_fails=3 fail_timeout=30s;
        server 10.4.7.128:6443     max_fails=3 fail_timeout=30s;
    }
    server {
        listen 7443;
        proxy_connect_timeout 2s;
        proxy_timeout 900s;
        proxy_pass kube-apiserver;
    }
}' >> /etc/nginx/nginx.conf


systemctl start nginx

systemctl enable nginx

#yum install keepalived -y
#
#
#echo '#!/bin/bash
##keepalived 监控端口脚本
##使用方法：
##在keepalived的配置文件中
##vrrp_script check_port {#创建一个vrrp_script脚本,检查配置
##    script "/etc/keepalived/check_port.sh 6379" #配置监听的端口
##    interval 2 #检查脚本的频率,单位（秒）
##}
#CHK_PORT=$1
#if [ -n "$CHK_PORT" ];then
#        PORT_PROCESS=`ss -lnt|grep $CHK_PORT|wc -l`
#        if [ $PORT_PROCESS -eq 0 ];then
#                echo "Port $CHK_PORT Is Not Used,End."
#                exit 1
#        fi
#else
#        echo "Check Port Cant Be Empty!"
#fi
#' > /etc/keepalived/check_port.sh
#
#chmod + /etc/keepalived/check_port.sh
