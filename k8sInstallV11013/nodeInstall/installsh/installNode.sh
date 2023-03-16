#!/bin/bash
master="10.129.51.132"
etcd1="10.129.52.142"
etcd2="10.129.52.162"
etcd3="10.129.52.194"
node="10.129.51.26;"
mpnode="node1=10.129.51.26;"

conf=/k8sInstallV11013/nodeInstall/config/
sslConf=/k8sInstallV11013/nodeInstall/config/ssl/
caConf=/etc/kubernetes/ssl/
##修改集群内kubelet组件的配置文件/etc/kubernetes/conf/kubelet（包含master，etcd除外）


###2）生成kube-apiserver组件的证书

mkdir -p /etc/kubernetes/ssl/
scp -rp root@"${master}":/etc/kubernetes/ssl/master-ca*  /etc/kubernetes/ssl/
cd /k8sInstallV11013/nodeInstall/config/ssl/output/
##\rm /k8sInstallV11013/nodeInstall/config/ssl/output/*
cfssl gencert --ca ${caConf}master-ca.pem --ca-key ${caConf}master-ca-key.pem --config ${sslConf}k8s-gencert.json --profile kubernetes ${sslConf}kube-proxy-csr.json | cfssljson --bare kube-proxy 
\rm /opt/token.csv
scp -rp root@"${master}":/etc/kubernetes/token.csv   /opt/
tk=$(awk -F'[,]+' '{print $1}' /opt/token.csv)
sed -ir  "s#BOOTSTRAP_TOKEN=.*#BOOTSTRAP_TOKEN=${tk}#g"  /k8sInstallV11013/nodeInstall/config/ssl/kg.sh
scp -rp ${sslConf}kg.sh   root@"${master}":/opt/
ssh root@"${master}" "cd /opt/;/bin/sh /opt/kg.sh"
###根据ca的基础json文件生成master的ca证书
arrNode=(${node//;/ })

for k in ${arrNode[@]}
do

scp -rp /k8sInstallV11013/nodeInstall/config/ssl/output/* root@"${k}":/etc/kubernetes/ssl/
scp -rp /k8sInstallV11013/masterInstall/docker/software/* root@"${k}":/root/
ssh root@"${k}"  "yum install -y yum-utils device-mapper-persistent-data lvm2;yum localinstall /root/docker-ce-18.03.0.ce-1.el7.centos.x86_64.rpm  -y;systemctl enable --now docker.service"
ssh root@"${k}"    "mkdir -p /etc/kubernetes/{ssl,conf} /etc/nginx  /etc/calico/ /etc/etcd/ssl/  /root/k8s/image/ /var/lib/{calico,kubelet}   /var/run/calico  /var/log/kube-audit/"

scp -rp ${conf}/nodeConf/* root@"${k}":/etc/kubernetes/conf/ 
scp -rp /k8sInstallV11013/masterInstall/starService/* root@"${k}":/usr/lib/systemd/system/
scp -rp /k8sInstallV11013/masterInstall/software/* root@"${k}":/usr/local/bin/ 
ssh root@"${k}" "sed -i 's@hostname-override=.*@hostname-override=$(hostname)\"@g' /etc/kubernetes/conf/kubelet"
ssh root@"${k}" "sed -i 's@node-ip=.*@node-ip=${k}\"@g' /etc/kubernetes/conf/kubelet"
ssh root@"${k}" "sed -i 's#k8s-master#k8s-node#g' /etc/kubernetes/conf/kubelet"
scp -rp root@"${master}":/etc/kubernetes/ssl/master-ca*  root@"${k}":/etc/kubernetes/ssl/
ssh root@"${k}" "chmod +x /usr/local/bin/*"
scp -rp /k8sInstallV11013/masterInstall/docker/dockertar/* root@"${k}":/root/k8s/image/
ssh root@"${k}"   "for i in \$(ls /root/k8s/image);do docker load -i  /root/k8s/image/\${i};done"
scp -rp /k8sInstallV11013/masterInstall/config/masterConf/baseconf/nginx.conf root@"${k}":/etc/nginx/
scp -rp root@"${master}":/opt/*.kubeconfig root@"${k}":/etc/kubernetes/conf/

scp -rp  root@"${etcd1}":/etc/etcd/ssl/* root@"${k}":/etc/etcd/ssl/
scp -rp  root@"${etcd1}":/etc/etcd/ssl/* root@"${k}":/etc/calico/


done


for j  in ${arrNode[@]}
do
ssh root@"${k}"   "systemctl daemon-reload;systemctl start nginx-proxy.service" &
ssh root@"${j}" "systemctl start kubelet.service;systemctl start kube-proxy.service"
done


sleep 2
ssh root@"${master}" "kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap"




###conf=/k8sInstallV11013/nodeInstall/config/


####十六、部署calico服务


ish=/k8sInstallV11013/nodeInstall/installsh/
mconf=/k8sInstallV11013/masterInstall/config/

####十六、部署calico服务

arr1=(${mpnode//;/ })

sed -i "s#Environment=.*#Environment=ETCD_ENDPOINTS=https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379#g" ${mconf}service/calico-node.service

for  i in ${arr1[@]}
do

       r=${i#*=}
       l=${i%=*}
       scp -rp root@"${master}":/etc/calico/*    root@"${r}":/etc/calico/
       scp -rp root@"${master}":/etc/etcd/ssl/*    root@"${r}":/etc/etcd/ssl/
###1）保证calico相关目录和启动文件已创建，具体目录如下：
       mkdir -p ${ish}${l};cp -a ${mconf}service/calico-node.service ${ish}${l}
####4）配置calico-node服务的启动文件
       sed -i -r "s#can-reach=[0-9.]+#can-reach=${r}#g;s#CALICO_K8S_NODE_REF=[0-9.a-z]+#CALICO_K8S_NODE_REF=${l}#g" ${ish}${l}/calico-node.service
       sed -i -r "s#NODENAME=[0-9.a-z]+#NODENAME=${l}#g" ${ish}${l}/calico-node.service
       ##ssh root@"${r}"  "mkdir -p /etc/calico/ /var/lib/calico /var/run/calico"
       ###scp -rp /k8sInstallV11013/etcdClusterInstall/config/ssl/output/* root@"${r}":/etc/calico/
       scp -rp ${ish}${l}/calico-node.service root@"${r}":/usr/lib/systemd/system/
       ssh root@"${r}"   "systemctl daemon-reload;systemctl start  calico-node.service"
       ssh root@"${r}"   "systemctl status  calico-node.service"
       \rm -rf ${ish}${l}


done

ssh root@"${master}" "/bin/sh /k8sInstallV11013/masterInstall/installSh/approve.sh"
