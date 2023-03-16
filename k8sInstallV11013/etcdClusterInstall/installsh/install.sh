#!/bin/sh

#ip根据实际情况做修改
etcdm1="etcd1=172.126.51.142"
etcdm2="etcd2=172.126.51.162"
etcdm3="etcd3=172.126.51.194"

etcd1="172.126.51.142"
etcd2="172.126.51.162"
etcd3="172.126.51.194"

#k8s的master节点
master1="10.129.51.132"
master2="10.129.51.117"

#修改文件etcd-server-csr.json 19-21行的节点ip信息
sed -i "19,21c  \"${etcd1}\",\n \"${etcd2}\",\n \"${etcd3}\""    /k8sInstallV11013/etcdClusterInstall/config/ssl/etcd-server-csr.json

####10.129.55.65 执行下面的操作

##1.生成证书
### 1)依据/k8sInstallV11013/etcdClusterInstall/config/ssl/k8s-root-ca-csr.json文件生成证书。

cd /k8sInstallV11013/etcdClusterInstall/config/ssl/output/
cfssl gencert --initca=true /k8sInstallV11013/etcdClusterInstall/config/ssl/etcd-ca-csr.json  | cfssljson --bare etcd-ca
echo "生成ca证书完成"
### #2)依据/k8sInstallV11013/etcdClusterInstall/config/ssl/etcd-gencert.json、etcd-csr.json和之前生成的CA证书文件etcd-root-ca.pem、etcd-root-ca-key.pem共同生成etcd的证书#。
cfssl gencert --ca /k8sInstallV11013/etcdClusterInstall/config/ssl/output/etcd-ca.pem --ca-key /k8sInstallV11013/etcdClusterInstall/config/ssl/output/etcd-ca-key.pem --config /k8sInstallV11013/etcdClusterInstall/config/ssl/etcd-config.json  /k8sInstallV11013/etcdClusterInstall/config/ssl/etcd-server-csr.json | cfssljson --bare etcd-server
echo "生成etcd证书完成"

#生成临时三个节点的配置目录,如果更多节点，则类似

echo "正在生成etcd节点的配置目录"
mkdir -p /k8sInstallV11013/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}
echo "完成创建etcd节点的配置目录"
#xargs  将命令的输出作为参数发送给另一个命令
echo /k8sInstallV11013/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}|xargs -n1 cp -a /k8sInstallV11013/etcdClusterInstall/config/etcd.conf
echo "完成复制etcd.conf模板配置文件到各个节点的配置目录下"

#修改临时生成的不同节点的配置文件
echo "正在修改etcd.conf的配置文件"
for j in ${etcdm1} ${etcdm2} ${etcdm3}
	do
	   r=${j#*=}
	   l=${j%=*}
	echo "正在修改 $j 的临时配置文件"
	sed -ir "s#ETCD_DATA_DIR=.*#ETCD_DATA_DIR=\\\"/var/lib/etcd/$l.etcd\\\"#g"     /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#ETCD_NAME=.*#ETCD_NAME=${l}#g"     /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#LISTEN_PEER_URLS=.*#LISTEN_PEER_URLS=\\\"https://${r}:2380\\\"#g"  /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#ADVERTISE_PEER_URLS=.*#ADVERTISE_PEER_URLS=\\\"https://${r}:2380\\\"#g"  /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#LISTEN_CLIENT_URLS=.*#LISTEN_CLIENT_URLS=\\\"https://${r}:2379,http://127.0.0.1:2379\\\"#g" /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#INITIAL_CLUSTER=.*#INITIAL_CLUSTER=\\\"etcd1=https://${etcd1}:2380,etcd2=https://${etcd2}:2380,etcd3=https://${etcd3}:2380\\\"#g" /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	sed -ir "s#ADVERTISE_CLIENT_URLS.*#ADVERTISE_CLIENT_URLS=\\\"https://${r}:2379\\\"#g" /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf
	ssh root@"${r}"  "mkdir -p /etc/etcd/"
	scp -rp /k8sInstallV11013/etcdClusterInstall/installsh/${l}/etcd.conf	root@"${r}":/etc/etcd/
	echo "完成 $j 的etcd.conf配置文件操作"
done
echo "修改所有不同节点的配置文件完成"


for j in ${etcd1} ${etcd2} ${etcd3}
do
	echo "开始配置 $j 节点上的etcd服务 "

	###################主节点创建etcd数据目录################################################################################。
	ssh root@${j} "mkdir -p /var/lib/etcd/ /etc/etcd/ssl/" 
	##2.配置"etcd.conf配置文件,这里要修改配置文件，需要补充。
	##3.配置etcd服务启动文件
	scp -rp /k8sInstallV11013/etcdClusterInstall/config/etcd.service 	root@"${j}":/usr/lib/systemd/system/
	##4.安装etcd服务二进制脚本
	##5. 以上10.129.55.65的相关操作都需要在其他节点执行一次。拷贝10.129.55.65相关的二进制文件etcd、etcdctl和/etc/etcd目录下的所有证书文件到各个etcd服务器节点
	scp -rp  /k8sInstallV11013/etcdClusterInstall/software/* root@"${j}":/usr/local/bin/
	######################################################################################################################
	##5. 以上10.129.55.65的相关操作都需要在其他节点执行一次。拷贝10.129.55.65相关的二进制文件etcd、etcdctl和/etc/etcd目录下的所有证书文件到各个etcd服务器节点
	scp -rp /k8sInstallV11013/etcdClusterInstall/config/ssl/output/*  root@"${j}":/etc/etcd/ssl

	ssh root@${j} "chmod +x /usr/local/bin/*"
	echo "完成配置 $j 节点上的etcd服务"
	 
	##6.启动所有节点上的etcd服务
done	
echo "完成配置所有etcd节点上的etcd配置文件..."

#复制所有证书到$master
for m in ${master1} ${master2}
do
echo "正在复制生成的证书到 $m"
ssh root@${m}  "mkdir -p /etc/etcd/ssl"
scp -rp /k8sInstallV11013/etcdClusterInstall/config/ssl/output/*  root@"${m}":/etc/etcd/ssl
echo "完成复制生成的证书到 $m"
done
echo "完成复制生成的证书到所有节点"

#启动所有etcd服务
for k in ${etcd1} ${etcd2}  ${etcd3}
do
echo "开始启动 $k节点的etcd服务"
ssh root@${k} "systemctl daemon-reload && systemctl enable etcd.service && systemctl start etcd.service" &
sleep 3
echo "完成启动 $k节点的etcd服务"
done
echo "完成启动所有节点的etcd服务"
sleep 2

#删除本机临时中间文件
rm -rf /k8sInstallV11013/etcdClusterInstall/installsh/{etcd1,etcd2,etcd3}
echo "删除所有中间：临时配置完成"

##sleep 10
#systemctl daemon-reload && systemctl enable etcd.service && systemctl start etcd.service &
#7.etcd集群健康状态检查，可在任意节点执行下面命令
echo "稍等，正在验证etcd集群健康状态"
etcdctl --ca-file=/etc/etcd/ssl/etcd-ca.pem --cert-file=/etc/etcd/ssl/etcd-server.pem  --key-file=/etc/etcd/ssl/etcd-server-key.pem --endpoints="https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379"  cluster-health



