#!/bin/sh
##1. etcd样例服务器10.129.55.65 生成密钥。
yum install -y expect
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
sleep 3
##2. 设置etcd服务器变量
##所有服务器的地址分号分隔开

server="10.129.52.xxx;10.129.52.xxx;10.129.52.xxx;10.129.51.xxx;10.129.51.xxx;10.129.51.xxx"

###添加主机文件 格式为主机名和ip,中间空格分隔。
myhostname="master1=10.129.51.xxx;master2=10.129.51.xxx;etcd1=10.129.52.xxx;etcd2=10.129.52.xxx;etcd3=10.129.52.xxx;node1=10.129.51.xxx"

arr=(${myhostname//;/ })
sed -i '3,8d' /k8sInstallV11013/etcdClusterInstall/config/hosts
for j in ${arr[@]}
do
   r=${j#*=}
   l=${j%=*}
   echo $l   $r
   echo "${r}  $l"  >> /k8sInstallV11013/etcdClusterInstall/config/hosts
done


export mypass=GRau6zipwGMpuSWk

array=(${server//;/ }) 
for i in ${array[@]}
do
##3. etcd集群节点间设置免密登录
   expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i
  expect {
    \"*yes/no*\" {send \"yes\r\"; exp_continue}
    \"*password*\" {send \"$mypass\r\"; exp_continue}
    \"*Password*\" {send \"$mypass\r\";}
  }"
 ##4. 时区设置和基础包安装，
 ##关闭防火墙selinux，
 ##ntp时间同步。
 ssh root@$i "yum install -y ntpdate net-tools vim wget lrzsz git telnet bash-completion;ntpdate -u 10.129.80.80;systemctl stop firewalld;systemctl disable firewalld;sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -rf" 
 scp -rp /k8sInstallV11013/etcdClusterInstall/config/hosts  root@$i:/etc/   
 ssh root@$i "echo '00 */2 * * * ntpdate -u 10.129.80.80 >/dev/null 2>&1'  >>/var/spool/cron/root;systemctl restart crond.service;echo -e  \"nameserver 10.129.51.250 \nnameserver 10.129.51.251\" >>/etc/resolv.conf"
done

