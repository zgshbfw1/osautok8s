
#!/bin/bash
#创建k8s服务的变量
KUBE_SVC='
kubelet
kube-scheduler
kube-proxy
kube-controller-manager
kube-apiserver
etcd
'

for kube_svc in ${KUBE_SVC};
do
echo "正在检查 $KUBE_SVC 服务的状态及是否有开机启动"
  # 检查$KUBE_SVC服务是否启动，如果启动则停止$KUBE_SVC服务
  if [[ `systemctl is-active ${kube_svc}` == 'active' ]]; then
    systemctl stop ${kube_svc}
  fi
  # 检查$KUBE_SVC是否开机自启，如果自启动则禁止$KUBE_SVC服务的开机启动
  if [[ `systemctl is-enabled ${kube_svc}` == 'enabled' ]]; then
    systemctl disable ${kube_svc}
  fi
done
echo "完成k8s相关所有服务的关停并关闭开机自启动"

# 停止所有容器
echo "停止所有容器"
docker stop $(docker ps -aq)
echo "完成停止所有容器"


# 删除所有容器
echo "正在删除所有容器"
docker rm -f $(docker ps -qa)
echo "已删除所有容器"

# 删除所有容器卷
echo "正在删除所有容器卷"
docker volume rm $(docker volume ls -q)
echo "完成删除所有的容器卷"

# 卸载mount目录
for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher;
do
echo "正在卸载 $mount 目录"
  umount $mount;
echo "完成卸载 $mount 目录"
done
echo "完成所有节点k8s相关的挂载目录"

# 备份目录
echo "正在备份所有k8s相关的数据目录"
mv /etc/kubernetes /etc/kubernetes-bak-$(date +"%Y%m%d%H%M")
mv /var/lib/etcd /var/lib/etcd-bak-$(date +"%Y%m%d%H%M")
mv /var/lib/rancher /var/lib/rancher-bak-$(date +"%Y%m%d%H%M")
cp -a /usr/local/bin /usr/local/bin-bak-$(date +"%Y%m%d%H%M")
mv /etc/etcd /etc/etcd-bak-$(date +"%Y%m%d%H%M")
mv /usr/lib/systemd/system/etcd.service /usr/lib/systemd/system/etcd.service-$(date +"%Y%m%d%H%M")
mv /opt/rke /opt/rke-bak-$(date +"%Y%m%d%H%M")
echo "完成所有k8s相关数据目录的备份"

# 删除残留路径
rm -rf /etc/ceph \
    /etc/cni \
    /opt/cni \
    /run/secrets/kubernetes.io \
    /run/calico \
    /run/flannel \
    /var/lib/calico \
    /var/lib/cni \
    /var/lib/kubelet \
    /var/log/containers \
    /var/log/kube-audit \
    /var/log/pods \
    /var/run/calico \
    /usr/libexec/kubernetes

# 清理网络接口
no_del_net_inter='
lo
docker0
eth
ens
bond
'

network_interface=`ls /sys/class/net`

for net_inter in $network_interface;
do
  if ! echo "${no_del_net_inter}" | grep -qE ${net_inter:0:3}; then
    ip link delete $net_inter
  fi
done

# 清理残留进程
port_list='
80
443
6443
2376
2379
2380
8472
9099
10250
10254
'

for port in $port_list;
do
  pid=`netstat -atlnup | grep $port | awk '{print $7}' | awk -F '/' '{print $1}' | grep -v - | sort -rnk2 | uniq`
  if [[ -n $pid ]]; then
    kill -9 $pid
  fi
done

kube_pid=`ps -ef | grep -v grep | grep kube | awk '{print $2}'`

if [[ -n $kube_pid ]]; then
  kill -9 $kube_pid
fi

# 清理Iptables表
# 注意：如果节点Iptables有特殊配置，以下命令请谨慎操作
sudo iptables --flush
sudo iptables --flush --table nat
sudo iptables --flush --table filter
sudo iptables --table nat --delete-chain
sudo iptables --table filter --delete-chain
systemctl stop docker
systemctl disable docker
