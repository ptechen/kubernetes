#!/bin/bash
cd /opt/kubernetes/server/bin/conf
kubectl config set-cluster myk8s \
  --certificate-authority=/opt/kubernetes/server/bin/certs/ca.pem \
  --embed-certs=true \
  --server=https://10.4.7.10:7443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=/opt/kubernetes/server/bin/certs/kube-proxy-client.pem \
  --client-key=/opt/kubernetes/server/bin/certs/kube-proxy-client-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context myk8s-context \
  --cluster=myk8s \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context myk8s-context --kubeconfig=kube-proxy.kubeconfig

echo '#!/bin/bash
ipvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
for i in $(ls $ipvs_mods_dir|grep -o "^[^.]*")
do
  /sbin/modinfo -F filename $i &>/dev/null
  if [ $? -eq 0 ];then
    /sbin/modprobe $i
  fi
done
' > /root/ipvs.sh

chmod +x /root/ipvs.sh

sh /root/ipvs.sh

echo '#!/bin/sh
hostname=$HOSTNAME
./kube-proxy \
  --cluster-cidr 172.7.0.1/16 \
  --hostname-override ${hostname}.host.com \
  --proxy-mode=ipvs \
  --ipvs-scheduler=nq \
  --kubeconfig ./conf/kube-proxy.kubeconfig
' > /opt/kubernetes/server/bin/kube-proxy.sh

chmod +x /opt/kubernetes/server/bin/kube-proxy.sh

localIP=$(ip addr|grep eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "add:")

localip=${localIP%/*}

backip=$(echo $localip|awk -F. '{ print $3"."$4 }')

back_ip=${backip//./-}

echo '[program:kube-proxy-'${back_ip}']
command=/opt/kubernetes/server/bin/kube-proxy.sh                     ; the program (relative uses PATH, can take args)
numprocs=1                                                           ; number of processes copies to start (def 1)
directory=/opt/kubernetes/server/bin                                 ; directory to cwd to before exec (def no cwd)
autostart=true                                                       ; start at supervisord start (default: true)
autorestart=true                                                     ; retstart at unexpected quit (default: true)
startsecs=30                                                         ; number of secs prog must stay running (def. 1)
startretries=3                                                       ; max # of serial start failures (default 3)
exitcodes=0,2                                                        ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                      ; signal used to kill process (default TERM)
stopwaitsecs=10                                                      ; max num secs to wait b4 SIGKILL (default 10)
user=root                                                            ; setuid to this UNIX account to run the program
redirect_stderr=true                                                 ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/logs/kubernetes/kube-proxy/proxy.stdout.log     ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                         ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                             ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                          ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                          ; emit events on stdout writes (default false)
' > /etc/supervisord.d/kube-proxy.ini

mkdir -p /data/logs/kubernetes/kube-proxy

supervisorctl update
