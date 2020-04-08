#!/bin/bash
/opt/zookeeper/bin/zkServer.sh stop

rm -rf /data/zookeeper/data/* /data/zookeeper/logs/*

echo 'tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs
clientPort=2181
' > /opt/zookeeper/conf/zoo.cfg

/opt/zookeeper/bin/zkServer.sh start

/opt/zookeeper/bin/zkServer.sh status

echo 'apiVersion: v1
kind: ConfigMap
metadata:
  name: dubbo-monitor-cm
  namespace: infra
data:
  dubbo.properties: |
    dubbo.container=log4j,spring,registry,jetty
    dubbo.application.name=simple-monitor
    dubbo.application.owner=OldboyEdu
    dubbo.registry.address=zookeeper://zk1.od.com:2181
    dubbo.protocol.port=20880
    dubbo.jetty.port=8080
    dubbo.jetty.directory=/dubbo-monitor-simple/monitor
    dubbo.charts.directory=/dubbo-monitor-simple/charts
    dubbo.statistics.directory=/dubbo-monitor-simple/statistics
    dubbo.log4j.file=/dubbo-monitor-simple/logs/dubbo-monitor.log
    dubbo.log4j.level=WARN
' > /data/k8s-yaml/dubbo-monitor/cm.yaml

echo 'kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-monitor
  namespace: infra
  labels:
    name: dubbo-monitor
spec:
  replicas: 1
  selector:
    matchLabels:
      name: dubbo-monitor
  template:
    metadata:
      labels:
        app: dubbo-monitor
        name: dubbo-monitor
    spec:
      containers:
      - name: dubbo-monitor
        image: harbor.od.com/infra/dubbo-monitor:latest
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 20880
          protocol: TCP
        imagePullPolicy: IfNotPresent
        volumeMounts:
          - name: configmap-volume
            mountPath: /dubbo-monitor-simple/conf
      volumes:
        - name: configmap-volume
          configMap:
            name: dubbo-monitor-cm
      imagePullSecrets:
      - name: harbor
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsUser: 0
      schedulerName: default-scheduler
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  revisionHistoryLimit: 7
  progressDeadlineSeconds: 600
' > /data/k8s-yaml/dubbo-monitor/dp.yaml

kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/cm.yaml
kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/dp.yaml

#iptables-save |grep -i postrouting
#iptables -t nat -D POSTROUTING -s 172.7.22.0/24 ! -o docker0 -j MASQUERADE
#iptables -t nat -I POSTROUTING -s 172.7.22.0/24 ! -d 172.7.0.0/16 ! -o docker0 -j MASQUERADE
