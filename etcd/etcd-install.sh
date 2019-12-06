#!/bin/bash

hostname=$HOSTNAME

ln -s $PWD/etcd-v* /opt/etcd

useradd -s /sbin/nologin -M etcd

mkdir -p /opt/etcd/certs

cp ../certs/pem/etcd-peer*.pem /opt/etcd/certs

ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" > localIp.txt
sed -i '1s/\/24//g' /root/localIp.txt
sed -i '2d' localIp.txt
localip=$(cat /root/localIp.txt)

echo '#!/bin/sh
./etcd --name etcd-server-'${hostname}' \
       --data-dir /data/etcd/etcd-server \
       --listen-peer-urls https://'${localip}':2380 \
       --listen-client-urls https://'${localip}':2379,http://127.0.0.1:2379 \
       --quota-backend-bytes 8000000000 \
       --initial-advertise-peer-urls https://'${localip}':2380 \
       --advertise-client-urls https://'${localip}':2379,http://127.0.0.1:2379 \
       --initial-cluster  etcd-server-7-126=https://10.4.7.126:2380,etcd-server-7-127=https://10.4.7.127:2380,etcd-server-7-128=https://10.4.7.128:2380 \
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
' > /opt/etcd/etcd-server-startup.sh

chmod +x /opt/etcd/etcd-server-startup.sh

chown -R etcd.etcd /opt/etcd /opt/etcd/certs

yum install supervisor -y

systemctl start supervisord

systemctl enable supervisord

echo '[program:etcd-server-'${hostname}']
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

# etcdctl cluster-health

# etcdctl member list
