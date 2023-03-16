#!/bin/sh
echo "k8s etcd运行状态如下"
etcdctl --ca-file=/etc/etcd/ssl/etcd-root-ca.pem --cert-file=/etc/etcd/ssl/etcd.pem \
--key-file=/etc/etcd/ssl/etcd-key.pem --endpoints="https://10.129.55.111:2379,https://10.129.55.112:2379,https://10.129.55.113:2379"  cluster-health

##
echo "k8s服务运行状态如下:"
systemctl list-units -t service -a|egrep "kube|docker|calico"

##集群运行装填如下
echo "集群运行状态信息如下"
kubectl get cs||egrep  "Unhealthy"
 
node=$(kubectl get nodes|awk -F'[ ]+' '$2~/NotReady/{print $1}')

echo "异常状态的node节点为: ${node:=空}" 

