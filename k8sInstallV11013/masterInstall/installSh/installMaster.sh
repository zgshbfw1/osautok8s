#!/bin/bash
allserver="172.126.51.132;172.126.51.117;172.126.51.142;172.126.51.162;172.126.51.194;172.126.51.26"
master="master1=172.126.51.132;master2=172.126.51.117"
etcd1="172.126.51.142"
etcd2="172.126.51.162"
etcd3="172.126.51.194"

conf=/k8sInstallV11013/masterInstall/config/
baseconf=/k8sInstallV11013/masterInstall/config/masterConf/baseconf/

#sed -i "s@https://.*@https://${etcd1},https://${etcd2},https://${etcd3}\"@g" ${conf}calicoconf/calico.sh
##修改集群内kube-apiserver组件的配置文件/etc/kubernetes/conf/apiserver（包含master，etcd除外）
##
##
sed -i "s@https://.*@https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379\"@g" ${baseconf}apiserver

b=$(echo "${allserver}"|sed 's#;#\",\\n \"#g')

###2）生成kube-apiserver组件的证书
#sed -i "6,8c  \"${b}\","    ${conf}masterConf/ssl/kube-apiserver-csr.json 

cd ${conf}/masterConf/ssl/output/
###根据ca的基础json文件生成master的ca证书
/bin/sh  ${conf}masterConf/ssl/ca.sh 
server=$(echo "${master}" |awk -F'[;=]' '{print "server "$2":6443;\\n","server "$4":6443;\\n"}')
sed -i "13,15c  ${server}" ${baseconf}nginx.conf

arr=(${master//;/ })

for  i in ${arr[@]}
do
              
       r=${i#*=}
       l=${i%*=}
       ###1.Master配置的相关目录（所有节点配置目录需预生成）
       ssh root@"${r}"   "mkdir -p /etc/kubernetes/ssl /etc/kubernetes/conf/ /etc/etcd/ssl/;mkdir -p /etc/nginx/ /root/k8s/image /var/log/kube-audit/"
       ###拷贝所有二进制文件、生成的ca证书文件、基本配置文件、启动文件到本机及其他master节点上。
       scp -rp ${baseconf}nginx.conf  root@"${r}":/etc/nginx/
       #scp -rp ${baseconf}token.csv  root@"${r}":/etc/kubernetes/
       scp -rp ${conf}service/*  root@"${r}":/usr/lib/systemd/system/
       
       scp -rp ${conf}masterConf/ssl/output/* root@"${r}":/etc/kubernetes/ssl/
       scp -rp ${baseconf}/*  root@"${r}":/etc/kubernetes/conf/
       scp -rp ${baseconf}nginx.repo  root@"${r}":/etc/yum.repos.d/
       scp -rp ${conf}masterConf/ssl/output/token.csv  root@"${r}":/etc/kubernetes/
       scp -rp /k8sInstallV11013/masterInstall/software/*  root@"${r}":/usr/local/bin/
       scp -rp /k8sInstallV11013/masterInstall/docker/software/* root@"${r}":/root/
       scp -rp /k8sInstallV11013/masterInstall/docker/dockertar/* root@"${r}":/root/k8s/image/
       
       scp -rp  root@"${etcd1}":/etc/etcd/ssl/* root@"${r}":/etc/etcd/ssl/
       scp -rp  root@"${etcd1}":/etc/etcd/ssl/* root@"${r}":/etc/calico/

       ###2）安装docker服务 将docker安装包一次性远程传输到所有其他master节点及node节点上： 4)启动Docker服务。
       ssh root@"${r}"  "yum install -y yum-utils device-mapper-persistent-data lvm2 nginx-1.12.2;yum localinstall /root/docker-ce-18.03.0.ce-1.el7.centos.x86_64.rpm  -y;systemctl enable --now docker.service"
       ssh root@"${r}"   "for i in \$(ls /root/k8s/image);do docker load -i  /root/k8s/image/\${i};done"    
 
       ssh root@"${r}"   "systemctl daemon-reload;systemctl start nginx-proxy.service"
       ssh root@"${r}"   "systemctl daemon-reload"
       ssh root@"${r}"   "sed -i \"s#advertise-address=.*#advertise-address=${r} --bind-address=${r} \\\"#g\" /etc/kubernetes/conf/apiserver"

       #ssh root@"${r}"  "systemctl start kube-apiserver.service" 
       ssh root@"${r}"  "chmod +x /usr/local/bin/hyperkube;systemctl daemon-reload;systemctl start kube-apiserver.service;systemctl start kube-scheduler.service;systemctl start kube-controller-manager.service" 
       ssh root@"${r}"  "systemctl status kube-apiserver.service;systemctl status kube-scheduler.service;systemctl status kube-controller-manager.service"        
 
done

kubectl  create  clusterrolebinding  kubelet-bootstrap   --clusterrole=system:node-bootstrapper   --user=kubelet-bootstrap
###conf=/k8sInstallV11013/masterInstall/config/

ish=/k8sInstallV11013/masterInstall/installSh/
sed -i "s#Environment=.*#Environment=ETCD_ENDPOINTS=https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379#g" ${conf}service/calico-node.service

####十六、部署calico服务

arr=(${master//;/ })

for  i in ${arr[@]}
do

       r=${i#*=}
       l=${i%=*}
###1）保证calico相关目录和启动文件已创建，具体目录如下：
       mkdir -p ${ish}${l};cp -a ${conf}service/calico-node.service ${ish}${l}
####4）配置calico-node服务的启动文件
       sed -i -r "s#can-reach=[0-9.]+#can-reach=${r}#g;s#CALICO_K8S_NODE_REF=[0-9.a-z]+#CALICO_K8S_NODE_REF=${l}#g" ${ish}${l}/calico-node.service
       ssh root@"${r}"  "mkdir -p /etc/calico/ /var/lib/calico /var/run/calico"
       ###scp -rp /k8sInstallV11013/etcdClusterInstall/config/ssl/output/* root@"${r}":/etc/calico/
       scp -rp ${ish}${l}/calico-node.service root@"${r}":/usr/lib/systemd/system/
       ssh root@"${r}"   "systemctl daemon-reload;systemctl start  calico-node.service"
       ssh root@"${r}"   "systemctl status  calico-node.service"
       \rm -rf ${ish}${l}


done

###创建cni插件和calico-kube-controllers服务
cyml=/k8sInstallV11013/masterInstall/baseYaml/calico/calico.yaml

ETCD_CERT=`cat /etc/etcd/ssl/etcd-server.pem | base64 | tr -d '\n'`
ETCD_KEY=`cat /etc/etcd/ssl/etcd-server-key.pem | base64 | tr -d '\n'`
ETCD_CA=`cat /etc/etcd/ssl/etcd-ca.pem | base64 | tr -d '\n'`
ETCD_ENDPOINTS="https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379"
###\cp calico.example.yaml ${cyml}

sed -i "s@.*etcd_endpoints:.*@\ \ etcd_endpoints:\ \"${ETCD_ENDPOINTS}\"@gi" ${cyml}

sed -i "s@.*etcd-cert:.*@\ \ etcd-cert:\ ${ETCD_CERT}@gi" ${cyml}
sed -i "s@.*etcd-key:.*@\ \ etcd-key:\ ${ETCD_KEY}@gi" ${cyml}
sed -i "s@.*etcd-ca:.*@\ \ etcd-ca:\ ${ETCD_CA}@gi" ${cyml}

sed -i 's@.*etcd_ca:.*@\ \ etcd_ca:\ "/calico-secrets/etcd-ca"@gi' ${cyml}
sed -i 's@.*etcd_cert:.*@\ \ etcd_cert:\ "/calico-secrets/etcd-cert"@gi' ${cyml}
sed -i 's@.*etcd_key:.*@\ \ etcd_key:\ "/calico-secrets/etcd-key"@gi' ${cyml}


sleep 2
####部署calico-node及calico-kube-controllers服务。
kubectl apply -f /k8sInstallV11013/masterInstall/baseYaml/calico/calico.yaml

kubectl apply -f /k8sInstallV11013/masterInstall/baseYaml/calico/rbac.yaml
##DNS
kubectl apply -f /k8sInstallV11013/masterInstall/baseYaml/dns/corednsConfigmap.yaml
kubectl apply -f /k8sInstallV11013/masterInstall/baseYaml/dns/coredns.yaml
##kubectl apply -f /k8sInstallV11013/masterInstall/installSh/dns-horizontal-autoscaler.yaml
kubectl apply -f /k8sInstallV11013/masterInstall/baseYaml/dash-board/kubernetes-dashboard.1.10.yaml
#sleep 1

#####部署完成检查服务状态。确保calico-node和calico-kube-controllers服务状态运行正常.
for  i in ${arr[@]}
do

   r=${i#*=}
   l=${i%=*}
   ssh root@"${r}"   "systemctl status  calico-node.service"
   ssh root@"${r}"  "systemctl status kube-apiserver.service;systemctl status kube-scheduler.service;systemctl status kube-controller-manager.service"


done


kubectl get cs

