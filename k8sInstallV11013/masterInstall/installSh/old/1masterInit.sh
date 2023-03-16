#!/bin/bash
allserver="10.129.55.61;10.129.55.65;10.129.55.155"
etcd1="10.129.55.61"
etcd2="10.129.55.65"
etcd3="10.129.55.155"
master1="10.129.55.61"
master2="10.129.55.65"
master3="10.129.55.155"
node="10.129.55.61;10.129.55.65;10.129.55.155"
#### /root/k8s/calico/calico.sh
#### ETCD_ENDPOINTS="https://10.129.55.30:2379,https://10.129.55.61:2379,https://10.129.55.65:2379"





sed -i "s@https://.*@https://${etcd1},https://${etcd2},https://${etcd3}\"@g"  /root/k8s/calico/calico.sh

#### apiserver:KUBE_ETCD_SERVERS="--etcd-servers=https://10.129.55.111:2379,https://10.129.55.112:2379,https://10.129.55.113:2379"
### /root/k8s/conf/apiserver 

sed -i "s@https://.*@https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379\"@g" /root/k8s/conf/apiserver 

#"10.129.55.111",
#    "10.129.55.112",
#    "10.129.55.113"
#####/root/k8s/etcd/ssl
sed -i "19,21c  \"${etcd1}\",\n \"${etcd2}\",\n \"${etcd3}\""    /root/k8s/etcd/ssl/etcd-csr.json

b=$(echo "${allserver}"|sed 's#;#\",\\n \"#g')

echo $b
sed -i "6,8c  \"${b}\","    /root/k8s/ssl/kube-apiserver-csr.json
### /root/k8s/ssl/kube-apiserver-csr.json 
###"10.129.55.111",
#    "10.129.55.112",
#    "10.129.55.113"

