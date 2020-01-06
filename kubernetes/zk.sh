#!/bin/bash

mkdir -p /usr/java

tar xf jdk-8u231-linux-x64.tar.gz -C /usr/java/

ln -s /usr/java/jdk1.8.0_231/ /usr/java/jdk

echo '
export JAVA_HOME=/usr/java/jdk
export PATH=$JAVA_HOME/bin:$JAVA_HOME/bin:$PATH
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
' >> /etc/profile

source /etc/profile


tar xf zookeeper-3.4.14.tar.gz -C /opt/

ln -s /opt/zookeeper-3.4.14/ /opt/zookeeper

mkdir -pv /data/zookeeper/data /data/zookeeper/logs

echo 'tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs
clientPort=2181
server.1=zk1.od.com:2888:3888
server.2=zk2.od.com:2888:3888
server.3=zk3.od.com:2888:3888
' > /opt/zookeeper/conf/zoo.cfg


# 添加域名解析

echo '
zk1                A    10.4.7.11
zk2                A    10.4.7.12
zk3                A    10.4.7.21
' >> /var/named/od.com.zone

systemctl restart named

# 11
echo '1' > /data/zookeeper/data/myid
# 12
echo '2' > /data/zookeeper/data/myid
# 21
echo '3' > /data/zookeeper/data/myid

/opt/zookeeper/bin/zkServer.sh start

ps aux|grep zoo

netstat -luntp|grep 2181

/opt/zookeeper/bin/zkCli.sh status


# /opt/zookeeper/bin/zkCli.sh -server localhost:2181

mkdir -pv /data/dockerfile/jenkins

# 200
ssh-keygen -t rsa -b 2048 -C "xxx@xx.xxx" -N "" -f /root/.ssh/id_rsa

echo 'FROM harbor.od.com/public/jenkins:v2.190.3
USER root
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    echo "Asia/Shanghai" >/etc/timezone
ADD id_rsa /root/.ssh/id_rsa
Add id_rsa.pub /root/.ssh/id_rsa.pub
ADD config.json /root/.docker/config.json
ADD get-docker.sh /get-docker.sh
RUN git config --global user.name "taochen"
RUN git config --global user.email "15736755067@163.com"
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config &&\
    /get-docker.sh
' > /data/dockerfile/jenkins/Dockerfile

cp /root/.ssh/id_rsa /data/dockerfile/jenkins/

cp /root/.docker/config.json /data/dockerfile/jenkins/

curl -fsSL get.docker.com -o /data/dockerfile/jenkins/get-docker.sh

chmod +x /data/dockerfile/jenkins/get-docker.sh

docker build . -t harbor.od.com/infra/jenkins:v2.190.3

# 21 / 22
kubectl create ns infra

kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n infra
# all
yum install nfs-utils -y

# 200
echo '/data/nfs-volume 10.4.7.0/24(rw,no_root_squash)' > /etc/exports

mkdir -pv /data/nfs-volume

systemctl start nfs

systemctl enable nfs

mkdir -pv /data/k8s-yaml/jenkins


echo 'kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: jenkins
  namespace: infra
  labels:
    name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      name: jenkins
  template:
    metadata:
      labels:
        app: jenkins
        name: jenkins
    spec:
      volumes:
      - name: data
        nfs:
          server: hdss7-200
          path: /data/nfs-volume/jenkins_home
      - name: docker
        hostPath:
          path: /run/docker.sock
          type: ""
      containers:
      - name: jenkins
        image: harbor.od.com/infra/jenkins:v2.190.3
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          protocol: TCP
        env:
        - name: JAVA_OPTS
          value: -Xmx512m -Xms512m
        volumeMounts:
        - name: data
          mountPath: /var/jenkins_home
        - name: docker
          mountPath: /run/docker.sock
      imagePullSecrets:
      - name: harbor
      securityContext:
        runAsUser: 0
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  revisionHistoryLimit: 7
  progressDeadlineSeconds: 600
' > /data/k8s-yaml/jenkins/dp.yaml

echo 'kind: Service
apiVersion: v1
metadata:
  name: jenkins
  namespace: infra
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: jenkins
' > /data/k8s-yaml/jenkins/svc.yaml

echo 'kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: jenkins
  namespace: infra
spec:
  rules:
  - host: jenkins.od.com
    http:
      paths:
      - path: /
        backend:
          serviceName: jenkins
          servicePort: 80
' > /data/k8s-yaml/jenkins/ingress.yaml

mkdir -pv /data/nfs-volume/jenkins_home

kubectl apply -f http://k8s-yaml.od.com/jenkins/dp.yaml
kubectl apply -f http://k8s-yaml.od.com/jenkins/svc.yaml
kubectl apply -f http://k8s-yaml.od.com/jenkins/ingress.yaml

kubectl get pods -n infra

cat /data/nfs-volume/jenkins_home/secrets/initialAdminPassword


mkdir -pv /data/nfs-volume/jenkins_home/maven-3.6.1-8u232

tar xf apache-maven-3.6.3-bin.tar.gz -C /data/nfs-volume/jenkins_home/maven-3.6.1-8u232
# vi /data/nfs-volume/jenkins_home/maven-3.6.1-8u232/conf/settings.xml
#<mirror>
#      <id>nexus-aliyun</id>
#      <mirrorOf>*</mirrorOf>
#      <name>Nexus aliyun</name>
#      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
#</mirror>

docker pull stanleyws/jre8:8u112

docker tag fa3a085d6ef1 harbor.od.com/public/jre:8u112

docker push harbor.od.com/public/jre:8u112

mkdir -pv /data/dockerfile/jre8

echo 'FROM harbor.od.com/public/jre:8u112
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    echo "Asia/Shanghai" >/etc/timezone
ADD config.yml /opt/prom/config.yml
ADD jmx_javaagent-0.3.1.jar /opt/prom/
WORKDIR /opt/project_dir
ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
' > /data/dockerfile/jre8/Dockerfile

wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O jmx_javaagent-0.3.1.jar

echo '---
rules:
  - pattern: ".*"
' > /data/dockerfile/jre8/config

echo '#!/bin/sh
M_OPTS="-Duser.timezone=Asia/Shanghai -javaagent:/opt/prom/jmx_javaagent-0.3.1.jar=$(hostname -i):${M_PORT:-"12346"}:/opt/prom/config.yml"
C_OPTS=${C_OPTS}
JAR_BALL=${JAR_BALL}
exec java -jar ${M_OPTS} ${C_OPTS} ${JAR_BALL}
' > /data/dockerfile/jre8/entrypoint.sh

chmod +x /data/dockerfile/jre8/entrypoint.sh

docker build . -t harbor.od.com/base/jre8:8u112

docker push harbor.od.com/base/jre8:8u112


#pipeline {
#  agent any
#    stages {
#      stage('pull') { //get project code from repo
#        steps {
#          sh "git clone ${params.git_repo} ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.app_name}/${env.BUILD_NUMBER} && git checkout ${params.git_ver}"
#        }
#      }
#      stage('build') { //exec mvn cmd
#        steps {
#          sh "cd ${params.app_name}/${env.BUILD_NUMBER}  && /var/jenkins_home/maven-${params.maven}/bin/${params.mvn_cmd}"
#        }
#      }
#      stage('package') { //move jar file into project_dir
#        steps {
#          sh "cd ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.target_dir} && mkdir project_dir && mv *.jar ./project_dir"
#        }
#      }
#      stage('image') { //build image and push to registry
#        steps {
#          writeFile file: "${params.app_name}/${env.BUILD_NUMBER}/Dockerfile", text: """FROM harbor.od.com/${params.base_image}
#ADD ${params.target_dir}/project_dir /opt/project_dir"""
#          sh "cd  ${params.app_name}/${env.BUILD_NUMBER} && docker build -t harbor.od.com/${params.image_name}:${params.git_ver}_${params.add_tag} . && docker push harbor.od.com/${params.image_name}:${params.git_ver}_${params.add_tag}"
#        }
#      }
#    }
#}


mkdir -pv /data/k8s-yaml/dubbo-demo-service

echo 'kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-demo-service
  namespace: app
  labels:
    name: dubbo-demo-service
spec:
  replicas: 1
  selector:
    matchLabels:
      name: dubbo-demo-service
  template:
    metadata:
      labels:
        app: dubbo-demo-service
        name: dubbo-demo-service
    spec:
      containers:
      - name: dubbo-demo-service
        image: harbor.od.com/app/dubbo-demo-service:master_191201_1200
        ports:
        - containerPort: 20880
          protocol: TCP
        env:
        - name: JAR_BALL
          value: dubbo-server.jar
        imagePullPolicy: IfNotPresent
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
' > /data/k8s-yaml/dubbo-demo-service/dp.yaml

kubectl create ns app

kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n app

kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-service/dp.yaml

git clone https://github.com/Jeromefromcn/dubbo-monitor.git

echo '##
# Copyright 1999-2011 Alibaba Group.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##
dubbo.container=log4j,spring,registry,jetty
dubbo.application.name=dubbo-monitor
dubbo.application.owner=OldboyEdu
dubbo.registry.address=zookeeper://zk1.od.com:2181?back_up=zk2.od.com:2182,zk3.od.com:2181
#dubbo.registry.address=zookeeper://127.0.0.1:2181
#dubbo.registry.address=redis://127.0.0.1:6379
#dubbo.registry.address=dubbo://127.0.0.1:9090
dubbo.protocol.port=20880
dubbo.jetty.port=8080
dubbo.jetty.directory=/dubbo-monitor-simpale/monitor
dubbo.charts.directory=/dubbo-monitor-simpale/charts
dubbo.statistics.directory=/dubbo-monitor-simpale/statistics
dubbo.log4j.file=logs/dubbo-monitor-simple.log
dubbo.log4j.level=WARN
' > /data/dockerfile/dubbo-monitor/dubbo-monitor-simple/conf/dubbo_origin.propertie

sed -r -i -e '/^nohup/{p;:a;N;$!ba;d}'  ./dubbo-monitor-simple/bin/start.sh && sed  -r -i -e "s%^nohup(.*)%exec \1%"  ./dubbo-monitor-simple/bin/start.sh

echo '#!/bin/bash
sed -e "s/{ZOOKEEPER_ADDRESS}/$ZOOKEEPER_ADDRESS/g" /dubbo-monitor-simple/conf/dubbo_origin.properties > /dubbo-monitor-simple/conf/dubbo.properties
cd `dirname $0`
BIN_DIR=`pwd`
cd ..
DEPLOY_DIR=`pwd`
CONF_DIR=$DEPLOY_DIR/conf

SERVER_NAME=`sed '/dubbo.application.name/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
SERVER_PROTOCOL=`sed '/dubbo.protocol.name/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
SERVER_PORT=`sed '/dubbo.protocol.port/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
LOGS_FILE=`sed '/dubbo.log4j.file/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`

if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME=`hostname`
fi

PIDS=`ps -f | grep java | grep "$CONF_DIR" |awk '{print $2}'`
if [ -n "$PIDS" ]; then
    echo "ERROR: The $SERVER_NAME already started!"
    echo "PID: $PIDS"
    exit 1
fi

if [ -n "$SERVER_PORT" ]; then
    SERVER_PORT_COUNT=`netstat -tln | grep $SERVER_PORT | wc -l`
    if [ $SERVER_PORT_COUNT -gt 0 ]; then
        echo "ERROR: The $SERVER_NAME port $SERVER_PORT already used!"
        exit 1
    fi
fi

LOGS_DIR=""
if [ -n "$LOGS_FILE" ]; then
    LOGS_DIR=`dirname $LOGS_FILE`
else
    LOGS_DIR=$DEPLOY_DIR/logs
fi
if [ ! -d $LOGS_DIR ]; then
    mkdir $LOGS_DIR
fi
STDOUT_FILE=$LOGS_DIR/stdout.log

LIB_DIR=$DEPLOY_DIR/lib
LIB_JARS=`ls $LIB_DIR|grep .jar|awk '{print "'$LIB_DIR'/"$0}'|tr "\n" ":"`

JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true "
JAVA_DEBUG_OPTS=""
if [ "$1" = "debug" ]; then
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
fi
JAVA_JMX_OPTS=""
if [ "$1" = "jmx" ]; then
    JAVA_JMX_OPTS=" -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
fi
JAVA_MEM_OPTS=""
BITS=`java -version 2>&1 | grep -i 64-bit`
if [ -n "$BITS" ]; then
    JAVA_MEM_OPTS=" -server -Xmx128m -Xms128m -Xmn256m -XX:PermSize=16m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
else
    JAVA_MEM_OPTS=" -server -Xms128m -Xmx128 -XX:PermSize=16m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
fi

echo -e "Starting the $SERVER_NAME ...\c"
exec java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS -classpath $CONF_DIR:$LIB_JARS com.alibaba.dubbo.container.Main > $STDOUT_FILE 2>&1
' > /data/dockerfile/dubbo-monitor/dubbo-monitor-simple/bin/start.sh

docker build . -t harbor.od.com/infra/dubbo-monitor:latest

mkdir -pv /data/k8s-yaml/dubbo-monitor

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

echo 'kind: Service
apiVersion: v1
metadata:
  name: dubbo-monitor
  namespace: infra
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  selector:
    app: dubbo-monitor
' > /data/k8s-yaml/dubbo-monitor/svc.yaml

echo 'kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-monitor
  namespace: infra
spec:
  rules:
  - host: dubbo-monitor.od.com
    http:
      paths:
      - path: /
        backend:
          serviceName: dubbo-monitor
          servicePort: 8080
' > /data/k8s-yaml/dubbo-monitor/ingress.yaml

kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/dp.yaml
kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/svc.yaml
kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/ingress.yaml

mkdir -pv /data/k8s-yaml/dubbo-demo-consumer

echo 'kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-demo-consumer
  namespace: app
  labels:
    name: dubbo-demo-consumer
spec:
  replicas: 1
  selector:
    matchLabels:
      name: dubbo-demo-consumer
  template:
    metadata:
      labels:
        app: dubbo-demo-consumer
        name: dubbo-demo-consumer
    spec:
      containers:
      - name: dubbo-demo-consumer
        image: harbor.od.com/app/dubbo-demo-consumer:master_2001010954
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 20880
          protocol: TCP
        env:
        - name: JAR_BALL
          value: dubbo-client.jar
        imagePullPolicy: IfNotPresent
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
' > /data/k8s-yaml/dubbo-demo-consumer/dp.yaml

echo 'kind: Service
apiVersion: v1
metadata:
  name: dubbo-demo-consumer
  namespace: app
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  selector:
    app: dubbo-demo-consumer
' > /data/k8s-yaml/dubbo-demo-consumer/svc.yaml

echo 'kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-demo-consumer
  namespace: app
spec:
  rules:
  - host: demo.od.com
    http:
      paths:
      - path: /
        backend:
          serviceName: dubbo-demo-consumer
          servicePort: 8080
' > /data/k8s-yaml/dubbo-demo-consumer/ingress.yaml

kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-consumer/dp.yaml
kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-consumer/svc.yaml
kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-consumer/ingress.yaml

