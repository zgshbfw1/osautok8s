#!/bin/sh
etcdm1="etcd1=10.129.55.61"
etcdm2="etcd2=10.129.55.65"
etcdm3="etcd3=10.129.55.155"
etcd1="10.129.55.61"
etcd2="10.129.55.65"
etcd3="10.129.55.155"

sed -i "19,21c  \"${etcd1}\",\n \"${etcd2}\",\n \"${etcd3}\""    /k8sInstall/etcdClusterInstall/config/ssl/etcd-server-csr.json

####10.129.55.65 执行下面的操作

##1.生成证书
### 1)依据/k8sInstall/etcdClusterInstall/config/ssl/k8s-root-ca-csr.json文件生成证书。

cd /k8sInstall/etcdClusterInstall/config/ssl/output/
cfssl gencert --initca=true /k8sInstall/etcdClusterInstall/config/ssl/etcd-ca-csr.json  | cfssljson --bare etcd-ca
### 2)依据/k8sInstall/etcdClusterInstall/config/ssl/etcd-gencert.json、etcd-csr.json和之前生成的CA证书文件etcd-root-ca.pem、etcd-root-ca-key.pem共同生成etcd的证书。
cfssl gencert --ca /k8sInstall/etcdClusterInstall/config/ssl/output/etcd-ca.pem --ca-key /k8sInstall/etcdClusterInstall/config/ssl/output/etcd-ca-key.pem --config /k8sInstall/etcdClusterInstall/config/ssl/etcd-config.json  /k8sInstall/etcdClusterInstall/config/ssl/etcd-server-csr.json | cfssljson --bare etcd-server

mkdir -p /k8sInstall/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}
echo /k8sInstall/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}|xargs -n1 cp -a /k8sInstall/etcdClusterInstall/config/etcd.conf

for j in ${etcdm1} ${etcdm2} ${etcdm3}
do
   r=${j#*=}
   l=${j%=*}
sed -ir "s#ETCD_DATA_DIR=.*#ETCD_DATA_DIR=\\\"/var/lib/etcd/$l.etcd\\\"#g"     /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#ETCD_NAME=.*#ETCD_NAME=${l}#g"     /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#LISTEN_PEER_URLS=.*#LISTEN_PEER_URLS=\\\"https://${r}:2380\\\"#g"  /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#ADVERTISE_PEER_URLS=.*#ADVERTISE_PEER_URLS=\\\"https://${r}:2380\\\"#g"  /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#LISTEN_CLIENT_URLS=.*#LISTEN_CLIENT_URLS=\\\"https://${r}:2379,http://127.0.0.1:2379\\\"#g" /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#INITIAL_CLUSTER=.*#INITIAL_CLUSTER=\\\"etcd1=https://${etcd1}:2380,etcd2=https://${etcd2}:2380,etcd3=https://${etcd3}:2380\\\"#g" /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
sed -ir "s#ADVERTISE_CLIENT_URLS.*#ADVERTISE_CLIENT_URLS=\\\"https://${r}:2379\\\"#g" /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf
scp -rp /k8sInstall/etcdClusterInstall/installsh/${l}/etcd.conf	root@"${r}":/etc/etcd/
done


echo "第一个for循环结束"


for j in ${etcd1} ${etcd2}  ${etcd3}
do
echo "进入第二个for循环 $j"


###################主节点创建etcd数据目录################################################################################。
ssh root@${j} "mkdir -p /var/lib/etcd/ /etc/etcd/ssl/" 
##2.配置"etcd.conf配置文件,这里要修改配置文件，需要补充。
##3.配置etcd服务启动文件
scp -rp /k8sInstall/etcdClusterInstall/config/etcd.service 	root@"${j}":/usr/lib/systemd/system/
##4.安装etcd服务二进制脚本
##5. 以上10.129.55.65的相关操作都需要在其他节点执行一次。拷贝10.129.55.65相关的二进制文件etcd、etcdctl和/etc/etcd目录下的所有证书文件到各个etcd服务器节点
scp -rp  /k8sInstall/etcdClusterInstall/software/{etcd,etcdctl} root@"${r}":/usr/local/bin/
######################################################################################################################
##5. 以上10.129.55.65的相关操作都需要在其他节点执行一次。拷贝10.129.55.65相关的二进制文件etcd、etcdctl和/etc/etcd目录下的所有证书文件到各个etcd服务器节点
scp -rp /k8sInstall/etcdClusterInstall/config/ssl/output/*  root@"${j}":/etc/etcd/ssl

ssh root@${j} "chmod +x /usr/local/bin/etcd /usr/local/bin/etcdctl"
 
##6.启动所有节点上的etcd服务
systemctl daemon-reload && systemctl enable etcd.service && systemctl start etcd.service &

done	

rm -rf /k8sInstall/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}
sleep 30

#7.etcd集群健康状态检查，可在任意节点执行下面命令
etcdctl --ca-file=/etc/etcd/ssl/etcd-ca.pem --cert-file=/etc/etcd/ssl/etcd-server.pem  --key-file=/etc/etcd/ssl/etcd-server-key.pem --endpoints="https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379"  cluster-health
