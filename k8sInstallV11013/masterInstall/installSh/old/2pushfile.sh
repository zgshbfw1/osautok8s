#!/bin/sh
yum install -y expect
ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
sleep 3
##所有服务器的地址分号分隔开
server="10.129.55.61;10.129.55.65;10.129.55.155"
myhostname="master1=10.129.55.61;master2=10.129.55.65;master3=10.129.55.155"

arr=(${myhostname//;/ })
sed -i '3,8d' /root/k8s/sysconf/hosts
for j in ${arr[@]}
do
   r=${j#*=}
   l=${j%=*}
   echo $l   $r
   echo "${r}  $l"  >> /root/k8s/sysconf/hosts
   
done
export mypass=GRau6zipwGMpuSWk

array=(${server//;/ }) 
for i in ${array[@]}
do
   expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i
  expect {
    \"*yes/no*\" {send \"yes\r\"; exp_continue}
    \"*password*\" {send \"$mypass\r\"; exp_continue}
    \"*Password*\" {send \"$mypass\r\";}
  }"
 scp -rp /root/k8s/ root@$i:/root/
 scp -rp /root/k8s/conf/root root@$i:/var/spool/cron/
 scp -rp /root/k8s/sysconf/kubernetes.conf  root@$i:/etc/sysctl.d/
 scp -rp /root/k8s/sysconf/hosts  root@$i:/etc/
 scp -rp /root/k8s/package/cfss*  root@$i:/usr/local/bin/
 scp -rp /root/k8s/package/{hyperkube,kubectl}  root@$i:/usr/local/bin/
 ssh root@$i "yum install -y ntpdate net-tools vim wget lrzsz git telnet bash-completion;ntpdate -u ntp.api.bz;systemctl stop firewalld;systemctl disable firewalld;sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -rf;reboot"


done


