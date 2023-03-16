#!/bin/sh
etcd1="etcd1=10.129.55.61"
etcd2="etcd2=10.129.55.65"
etcd3="etcd3=10.129.55.155"

#生成证书
cd /root/k8s/etcd/ssl
cfssl gencert --ca /root/k8s/etcd/ssl/etcd-root-ca.pem --ca-key /root/k8s/etcd/ssl/etcd-root-ca-key.pem --config /root/k8s/etcd/ssl/etcd-gencert.json --profile kubernetes /root/k8s/etcd/ssl/etcd-csr.json | cfssljson --bare etcd


for j in ${etcd1} ${etcd2}  ${etcd3}
do

    r=${j#*=}
    l=${j%=*}


sed -i "s#peer-urls=https://.*#peer-urls=https://${r}:2380 \\\#g;s#listen-client-urls.*#listen-client-urls=https://${r}:2379,http://${r}:2390,http://127.0.0.1:2379 \\\#g;s#advertise-client-urls.*#advertise-client-urls=https://${r}:2379 \\\#g"  /root/k8s/etcd/system/${l}.service
sed -i "s#initial-cluster=.*#initial-cluster=etcd1=https://${etcd1#*=}:2380,etcd2=https://${etcd2#*=}:2380,etcd3=https://${etcd3#*=}:2380 \\\#g;s#name=.*#name=${l} \\\#g" /root/k8s/etcd/system/${l}.service

scp -rp  /root/k8s/etcd/etcd-v3.2.18-linux-amd64/{etcd,etcdctl} root@"${r}":/usr/local/bin/
scp -rp /root/k8s/etcd/system/${l}.service  root@"${r}":/usr/lib/systemd/system/
ssh root@"${r}" "mkdir -p /var/lib/etcd/default.etcd"
scp -rp /root/k8s/etcd/ssl/  root@"${r}":/etc/etcd/
done



exit 1
exit 1
exit 1
sed -i "s#peer-urls=https://.*#peer-urls=https://${etcd1}:2380 \\\#g;s#listen-client-urls.*#listen-client-urls=https://${etcd1}:2379,http://${etcd1}:2390,http://127.0.0.1:2379 \\\#g;s#advertise-client-urls.*#advertise-client-urls=https://${etcd1}:2379 \\\#g"  /root/k8s/etcd/system/etcd1.service

sed -i "s#initial-cluster=.*#initial-cluster=etcd1=https://${etcd1}:2380,etcd2=https://${etcd2}:2380,etcd3=https://${etcd3}:2380 \\\#g;s#name=.*#name=${etcd1} \\\#g" /root/k8s/etcd/system/etcd1.service

exit 1
for i in ${etcd1} ${etcd2}  ${etcd3}
do
echo "$i"
scp -rp  /root/k8s/etcd/etcd-v3.2.18-linux-amd64/{etcd,etcdctl} root@"${i}":/usr/local/bin/
done
