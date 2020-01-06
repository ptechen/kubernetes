#!/bin/bash

docker pull bitnami/heapster:1.5.4

docker tag b2807e671446 harbor.od.com/public/heapster:v1.5.4

docker push harbor.od.com/public/heapster:v1.5.4

mkdir -p /data/k8s-yaml/heapster

echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: heapster
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: heapster
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:heapster
subjects:
- kind: ServiceAccount
  name: heapster
  namespace: kube-system
' > /data/k8s-yaml/heapster/rbac.yaml

echo 'apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: heapster
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: heapster
    spec:
      serviceAccountName: heapster
      containers:
      - name: heapster
        image: harbor.od.com/public/heapster:v1.5.4
        imagePullPolicy: IfNotPresent
        command:
        - /opt/bitnami/heapster/bin/heapster
        - --source=kubernetes:https://kubernetes.default
' > /data/k8s-yaml/heapster/dp.yaml

echo 'apiVersion: v1
kind: Service
metadata:
  labels:
    task: monitoring
    # For use as a Cluster add-on (https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)
    # If you are NOT using this as an addon, you should comment out this line.
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: Heapster
  name: heapster
  namespace: kube-system
spec:
  ports:
  - port: 80
    targetPort: 8082
  selector:
    k8s-app: heapster
' > /data/k8s-yaml/heapster/svc.yaml


# hdss7-21 或 hdss7-22上
#kubectl apply -f http://k8s-yaml.od.com/heapster/rbac.yaml
#kubectl apply -f http://k8s-yaml.od.com/heapster/dp.yaml
#kubectl apply -f http://k8s-yaml.od.com/heapster/svc.yaml

