#!/bin/bash

#docker pull kubernetes/pause
#docker tag f9d5de079539 harbor.od.com/public/pause:latest
#docker push harbor.od.com/public/pause:latest
# kubelet

cd /opt/kubernetes/server/bin/conf

kubectl config set-cluster myk8s \
  --certificate-authority=/opt/kubernetes/server/bin/certs/ca.pem \
  --embed-certs=true \
  --server=https://10.4.7.10:7443 \
  --kubeconfig=kubelet.kubeconfig

kubectl config set-credentials k8s-node \
  --client-certificate=/opt/kubernetes/server/bin/certs/client.pem \
  --client-key=/opt/kubernetes/server/bin/certs/client-key.pem \
  --embed-certs=true \
  --kubeconfig=kubelet.kubeconfig

kubectl config set-context myk8s-context \
  --cluster=myk8s \
  --user=k8s-node \
  --kubeconfig=kubelet.kubeconfig

kubectl config use-context myk8s-context --kubeconfig=kubelet.kubeconfig


echo 'apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-node
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: k8s-node
' > /opt/kubernetes/server/bin/conf/k8s-node.yaml

kubectl create -f k8s-node.yaml

kubectl get clusterrolebinding k8s-node -o yaml

echo '#!/bin/sh
hostname=$HOSTNAME
./kubelet \
  --anonymous-auth=false \
  --cgroup-driver systemd \
  --cluster-dns 192.168.0.2 \
  --cluster-domain cluster.local \
  --runtime-cgroups=/systemd/system.slice \
  --kubelet-cgroups=/systemd/system.slice \
  --fail-swap-on="false" \
  --client-ca-file ./certs/ca.pem \
  --tls-cert-file ./certs/kubelet.pem \
  --tls-private-key-file ./certs/kubelet-key.pem \
  --hostname-override ${hostname}.host.com \
  --image-gc-high-threshold 20 \
  --image-gc-low-threshold 10 \
  --kubeconfig ./conf/kubelet.kubeconfig \
  --log-dir /data/logs/kubernetes/kube-kubelet \
  --pod-infra-container-image harbor.od.com/public/pause:latest \
  --root-dir /data/kubelet
' > /opt/kubernetes/server/bin/kubelet.sh

chmod +x /opt/kubernetes/server/bin/kubelet.sh

mkdir -p /data/logs/kubernetes/kube-kubelet

mkdir -p /data/kubelet

localIP=$(ip addr|grep eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "add:")

localip=${localIP%/*}

backip=$(echo $localip|awk -F. '{ print $3"."$4 }')

back_ip=${backip//./-}

echo '[program:kube-kubelet-'${back_ip}']
command=/opt/kubernetes/server/bin/kubelet.sh     ; the program (relative uses PATH, can take args)
numprocs=1                                        ; number of processes copies to start (def 1)
directory=/opt/kubernetes/server/bin              ; directory to cwd to before exec (def no cwd)
autostart=true                                    ; start at supervisord start (default: true)
autorestart=true              		          ; retstart at unexpected quit (default: true)
startsecs=30                                      ; number of secs prog must stay running (def. 1)
startretries=3                                    ; max # of serial start failures (default 3)
exitcodes=0,2                                     ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                   ; signal used to kill process (default TERM)
stopwaitsecs=10                                   ; max num secs to wait b4 SIGKILL (default 10)
user=root                                         ; setuid to this UNIX account to run the program
redirect_stderr=true                              ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/logs/kubernetes/kube-kubelet/kubelet.stdout.log   ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                      ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                          ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                       ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                       ; emit events on stdout writes (default false)
' > /etc/supervisord.d/kube-kubelet.ini


supervisorctl update
sleep 3

kubectl get nodes
