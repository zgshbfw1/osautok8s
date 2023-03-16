#!/bin/sh
master="master1=10.129.55.61;master2=10.129.55.65;master3=10.129.55.155"

cd /root/k8s/ssl/
/bin/sh  /root/k8s/ssl/ca.sh 
server=$(echo "${master}" |awk -F'[;=]' '{print "server "$2":6443;\\n","server "$4":6443;\\n","server "$6":6443;\\n"}')
sed -i "13,15c  ${server}" /root/k8s/conf/nginx.conf

arr=(${master//;/ })

for  i in ${arr[@]}
do
       
       r=${i#*=}
       ssh root@"${r}"   "mkdir -p /etc/kubernetes/;mkdir -p /etc/nginx/"
       
       scp -rp /root/k8s/conf/nginx.conf  root@"${r}":/etc/nginx/
       scp -rp /root/k8s/systemd/*  root@"${r}":/usr/lib/systemd/system/
       
       scp -rp /root/k8s/ssl root@"${r}":/etc/kubernetes/
       scp -rp /root/k8s/conf  root@"${r}":/etc/kubernetes/
       scp -rp /root/k8s/conf/nginx.repo  root@"${r}":/etc/yum.repos.d/nginx.repo
       scp -rp /root/k8s/conf/token.csv  root@"${r}":/etc/kubernetes/
       
       if [ "${r}" = "10.129.55.61"  ];then
          ssh root@"${r}" "kubectl  create  clusterrolebinding  kubelet-bootstrap   --clusterrole=system:node-bootstrapper   --user=kubelet-bootstrap"          
       fi

       ssh root@"${r}"  "yum install -y yum-utils device-mapper-persistent-data lvm2 nginx-1.12.2;yum localinstall /root/k8s/package/docker-ce-18.03.0.ce-1.el7.centos.x86_64.rpm  -y;systemctl enable --now docker.service"
       ssh root@"${r}"   "for i in \$(ls /root/k8s/image);do docker load -i  /root/k8s/image/\${i};done"    
 
       ##ssh root@"${r}"   "systemctl daemon-reload;systemctl start nginx-proxy.service"
       ssh root@"${r}"   "systemctl daemon-reload"
       ssh root@"${r}"   "sed -i \"s#advertise-address=.*#advertise-address=${r} --bind-address=${r} \\\"#g\" /etc/kubernetes/conf/apiserver"
       #ssh root@"${r}"  "systemctl start kube-apiserver.service" 
       ssh root@"${r}"  "systemctl start kube-apiserver.service;systemctl;systemctl start kube-scheduler.service;systemctl start kube-controller-manager.service" 
        
 
done






