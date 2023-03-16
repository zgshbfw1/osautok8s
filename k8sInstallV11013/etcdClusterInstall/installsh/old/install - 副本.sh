#!/bin/sh
etcd1="etcd1=10.129.55.61"
etcd2="etcd2=10.129.55.65"
etcd3="etcd3=10.129.55.155"

####10.129.55.65 执行下面的操作

##1.生成证书
### 1)依据/k8sInstall/etcdClusterInstall/config/ssl/k8s-root-ca-csr.json文件生成证书。
cfssl gencert --initca=true /k8sInstall/etcdClusterInstall/config/ssl/k8s-root-ca-csr.json | cfssljson --bare k8s-root-ca
### 2)依据/k8sInstall/etcdClusterInstall/config/ssl/etcd-gencert.json、etcd-csr.json和之前生成的CA证书文件etcd-root-ca.pem、etcd-root-ca-key.pem共同生成etcd的证书。
cfssl gencert --ca /k8sInstall/etcdClusterInstall/config/ssl/output/etcd-root-ca.pem --ca-key /k8sInstall/etcdClusterInstall/config/ssl/output/etcd-root-ca-key.pem --config /k8sInstall/etcdClusterInstall/config/ssl/etcd-gencert.json --profile kubernetes /k8sInstall/etcdClusterInstall/config/ssl/etcd-csr.json | cfssljson --bare etcd




for j in ${etcd1} ${etcd2}  ${etcd3}
do

    r=${j#*=}
    l=${j%=*}
	
###################主节点创建etcd数据目录################################################################################。
ssh root@$r "mkdir -p /var/lib/etcd/" 
################################################################################################################################
	


##2.配置etcd.conf配置文件,这里要修改配置文件，需要补充。
cp -a /k8sInstall/etcdClusterInstall/config/etcd.conf	/etc/etcd/

##3.配置etcd服务启动文件
cp -a /k8sInstall/etcdClusterInstall/config/etcd.service 	/usr/lib/systemd/system/



##4.安装etcd服务二进制脚本
cp -a /k8sInstall/etcdClusterInstall/software/{etcd,etcdctl} 	/usr/local/bin

######################################################################################################################
##5. 以上10.129.55.65的相关操作都需要在其他节点执行一次。拷贝10.129.55.65相关的二进制文件etcd、etcdctl和/etc/etcd目录下的所有证书文件到各个etcd服务器节点

scp -rp  /k8sInstall/etcdClusterInstall/software/{etcd,etcdctl} root@"${r}":/usr/local/bin/
scp -rp /k8sInstall/etcdClusterInstall/conf/${l}.service  root@"${r}":/usr/lib/systemd/system/
ssh root@"${r}" "mkdir -p /var/lib/etcd/default.etcd"
scp -rp /k8sInstall/etcdClusterInstall/config/ssl/output/*  root@"${r}":/etc/etcd/ssl

##6.启动所有节点上的etcd服务
systemctl daemon-reload && systemctl enable etcd.service && systemctl start etcd.service

done	

##7.etcd集群健康状态检查，可在任意节点执行下面命令
etcdctl --ca-file=/etc/etcd/ssl/etcd-root-ca.pem --cert-file=/etc/etcd/ssl/etcd.pem \
> --key-file=/etc/etcd/ssl/etcd-key.pem --endpoints="https://10.129.55.61:2379,https://10.129.55.65:2379,https://10.129.55.155:2379"  cluster-health



