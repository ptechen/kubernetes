#!/bin/bash

yum install epel-release -y

tar xf etcd-v3.1.20-linux-amd64.tar.gz -C /opt

ln -s /opt/etcd-v3.1.20-linux-amd64 /opt/etcd

useradd -s /sbin/nologin -M etcd

mkdir -p /opt/etcd/certs

cp ../certs/pem/etcd-peer*.pem /opt/etcd/certs
cp ../certs/pem/ca.pem /opt/etcd/certs
localIP=$(ip addr|grep eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "add:")

localip=${localIP%/*}

backip=$(echo $localip|awk -F. '{ print $3"."$4 }')

back_ip=${backip//./-}
echo '#!/bin/sh
./etcd --name etcd-server-'${back_ip}' \
       --data-dir /data/etcd/etcd-server \
       --listen-peer-urls https://'${localip}':2380 \
       --listen-client-urls https://'${localip}':2379,http://127.0.0.1:2379 \
       --quota-backend-bytes 8000000000 \
       --initial-advertise-peer-urls https://'${localip}':2380 \
       --advertise-client-urls https://'${localip}':2379,http://127.0.0.1:2379 \
       --initial-cluster  etcd-server-7-12=https://10.4.7.12:2380,etcd-server-7-21=https://10.4.7.21:2380,etcd-server-7-22=https://10.4.7.22:2380 \
       --ca-file ./certs/ca.pem \
       --cert-file ./certs/etcd-peer.pem \
       --key-file ./certs/etcd-peer-key.pem \
       --client-cert-auth  \
       --trusted-ca-file ./certs/ca.pem \
       --peer-ca-file ./certs/ca.pem \
       --peer-cert-file ./certs/etcd-peer.pem \
       --peer-key-file ./certs/etcd-peer-key.pem \
       --peer-client-cert-auth \
       --peer-trusted-ca-file ./certs/ca.pem \
       --log-output stdout
#       --initial-cluster-state=existing
' > /opt/etcd/etcd-server-startup.sh

mkdir -p /data/etcd/etcd-server

chown -R etcd.etcd /data/etcd/etcd-server

chmod +x /opt/etcd/etcd-server-startup.sh

yum install supervisor -y

systemctl start supervisord

systemctl enable supervisord

echo '[program:etcd-server-'${back_ip}']
command=/opt/etcd/etcd-server-startup.sh                        ; the program (relative uses PATH, can take args)
numprocs=1                                                      ; number of processes copies to start (def 1)
directory=/opt/etcd                                             ; directory to cwd to before exec (def no cwd)
autostart=true                                                  ; start at supervisord start (default: true)
autorestart=true                                                ; retstart at unexpected quit (default: true)
startsecs=30                                                    ; number of secs prog must stay running (def. 1)
startretries=3                                                  ; max # of serial start failures (default 3)
exitcodes=0,2                                                   ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                 ; signal used to kill process (default TERM)
stopwaitsecs=10                                                 ; max num secs to wait b4 SIGKILL (default 10)
user=etcd                                                       ; setuid to this UNIX account to run the program
redirect_stderr=true                                            ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/logs/etcd-server/etcd.stdout.log           ; stdout log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                    ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                        ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                     ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                     ; emit events on stdout writes (default false)
' > /etc/supervisord.d/etcd-server.ini

mkdir -p /data/logs/etcd-server

chown -R etcd.etcd /data/logs/etcd-server

ln -s /opt/etcd/etcdctl /usr/bin/etcdctl

cd /opt/etcd
chown -R etcd.etcd ./

chown -R etcd.etcd /opt/etcd/certs

yum install supervisor -y

systemctl start supervisord

systemctl enable supervisord

supervisorctl update
# etcdctl cluster-health

# etcdctl member list
