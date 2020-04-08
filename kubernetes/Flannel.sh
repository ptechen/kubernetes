#!/bin/bash
etcd_cluster='https://10.4.7.12:2379,https://10.4.7.21:2379,https://10.4.7.22:2379'

mkdir -p /opt/flannel-v1.11.0

tar xf flannel-v0.11.0-linux-amd64.tar.gz -C /opt/flannel-v1.11.0/

ln -s /opt/flannel-v1.11.0 /opt/flannel

mkdir -p /opt/flannel/certs

cp /opt/kubernetes/server/bin/certs/ca.pem /opt/flannel/certs/ca.pem
cp /opt/kubernetes/server/bin/certs/client.pem /opt/flannel/certs/client.pem
cp /opt/kubernetes/server/bin/certs/client-key.pem /opt/flannel/certs/client-key.pem

localIP=$(ip addr|grep eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "add:")

localip=${localIP%/*}

backip=$(echo $localip|awk -F. '{ print $3"."$4 }')

back_ip=${backip//./-}

echo 'FLANNEL_NETWORK=172.7.0.0/16
FLANNEL_SUBNET=172.'$backip'.1/24
FLANNEL_MTU=1500
FLANNEL_IPMASQ=false
' > /opt/flannel/subnet.env
#FLANNEL_ETCD_ENDPOINTS="https://'$localip':2379"
#FLANNEL_ETCD_PREFIX="/coreos.com/network"
echo '#!/bin/sh
./flanneld \
  --public-ip='${localip}' \
  --etcd-endpoints='${etcd_cluster}' \
  --etcd-keyfile=./certs/client-key.pem \
  --etcd-certfile=./certs/client.pem \
  --etcd-cafile=./certs/ca.pem \
  --iface=eth0 \
  --subnet-file=./subnet.env \
  --healthz-port=2401
' > /opt/flannel/flanneld.sh

chmod +x /opt/flannel/flanneld.sh

etcdctl set /coreos.com/network/config '{"Network": "172.7.0.0/16", "Backend": {"Type": "host-gw"}}'

etcdctl get /coreos.com/network/config

echo '[program:flanneld-'${back_ip}']
command=/opt/flannel/flanneld.sh                             ; the program (relative uses PATH, can take args)
numprocs=1                                                   ; number of processes copies to start (def 1)
directory=/opt/flannel                                       ; directory to cwd to before exec (def no cwd)
autostart=true                                               ; start at supervisord start (default: true)
autorestart=true                                             ; retstart at unexpected quit (default: true)
startsecs=30                                                 ; number of secs prog must stay running (def. 1)
startretries=3                                               ; max # of serial start failures (default 3)
exitcodes=0,2                                                ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                              ; signal used to kill process (default TERM)
stopwaitsecs=10                                              ; max num secs to wait b4 SIGKILL (default 10)
user=root                                                    ; setuid to this UNIX account to run the program
redirect_stderr=true                                         ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/logs/flanneld/flanneld.stdout.log       ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                 ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                     ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                  ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                  ; emit events on stdout writes (default false)
killagroup=true
stopasgroup=true
' > /etc/supervisord.d/flannel.ini

mkdir -p /data/logs/flanneld
supervisorctl update

yum install -y iptables-services

systemctl start iptables

systemctl enable iptables

#sleep 5
#
iptablesRule="iptables -t nat -D POSTROUTING -s 172.3.222.0/24 ! -o docker0 -j MASQUERADE"
echo ${iptablesRule}|awk '{run=$0;system(run)}'
#
iptablesRule="iptables -t nat -I POSTROUTING -s 172.3.222.0/24 ! -d 172.7.0.0/16 ! -o docker0 -j MASQUERADE"
echo ${iptablesRule}|awk '{run=$0;system(run)}'
#
iptables -t filter -D INPUT -j REJECT --reject-with icmp-host-prohibited
iptables -t filter -D FORWARD -j REJECT --reject-with icmp-host-prohibited
#iptables-save |grep -i postrouting
#iptables-save |grep -i reject
iptables-save > /etc/sysconfig/iptables

# route -n
#route add -net 172.7.21.0/24 gw 10.4.7.21 dev eth0
#route add -net 172.7.22.0/24 gw 10.4.7.22 dev eth0
#route add -net 172.3.221.0/24 gw 192.168.3.221 dev ens33
#route add -net 172.3.222.0/24 gw 192.168.3.222 dev ens33