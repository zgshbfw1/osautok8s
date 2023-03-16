#!/bin/sh
master="master1=10.129.55.61;master2=10.129.55.65;master3=10.129.55.155"
etcd1="10.129.55.61"
etcd2="10.129.55.65"
etcd3="10.129.55.155"

conf=/k8sInstallV11013/masterInstall/config/
ish=/k8sInstallV11013/masterInstall/installSh/
sed -i "s#Environment=.*#Environment=ETCD_ENDPOINTS=https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379#g" ${conf}service/calico-node.service



arr=(${master//;/ })

for  i in ${arr[@]}
do
              
       r=${i#*=}
       l=${i%=*}
       mkdir -p ${ish}${l};cp -a ${conf}service/calico-node.service ${ish}${l} 
       sed -i -r "s#can-reach=[0-9.]+#can-reach=${r}#g;s#CALICO_K8S_NODE_REF=[0-9.a-z]+#CALICO_K8S_NODE_REF=${l}#g" ${ish}${l}/calico-node.service
       ssh root@"${r}"  "mkdir -p /etc/calico/ /var/lib/calico /var/run/calico"
       scp -rp /k8sInstallV11013/etcdClusterInstall/config/ssl/output/* root@"${r}":/etc/calico/
       scp -rp ${ish}${l}/calico-node.service root@"${r}":/usr/lib/systemd/system/
       ssh root@"${r}"   "systemctl daemon-reload;systemctl start  calico-node.service"
       \rm -rf ${ish}${l}

       
done

