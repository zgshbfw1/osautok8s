# 自动化部署Kubernetes

- shell自动化部署Kubernetes v1.10.13版本（支持TLS双向认证、RBAC授权、calicol网络、ETCD集群、Kuber-Proxy等）。

## 版本明细：Release-v1.10.13

- 测试通过系统：CentOS Linux release 7.2.1511 (Core)
- 内核 版本Linux master1 3.10.0-327
- Kubernetes： v1.10.13
- Etcd: etcd Version: 3.2.18
- Docker: Docker version 18.03.0-ce, build 0520e24
- calico： v3.1.0
- CNI-Plugins： v0.7.0 建议部署节点：最少三个节点，请配置好主机名解析（必备）

## 架构介绍

1. 
2. 
3. 
4. 

## 团队成员（zgshbfw）：

- jinzhesheng
- gaobo
- caochun

# 部署手册

| **手动部署** | [1.系统初始化](https://github.com/unixhot/salt-kubebin/blob/master/docs/init.md) | [2.ETCD集群部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/ca.md) | [3.ETCD集群部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/etcd-install.md) | [4.Master节点部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/master.md) | [5.Node节点部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/node.md) | [6.calico部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/flannel.md) | [7.应用创建](https://github.com/unixhot/salt-kubebin/blob/master/docs/app.md) |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **必备插件** | [1.CoreDNS部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/coredns.md) | [2.Dashboard部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/dashboard.md) | [3.Heapster部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/heapster.md) | [4.Ingress部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/ingress.md) | [5.CI/CD](https://github.com/unixhot/devops-x)               | [6.Helm部署](https://github.com/unixhot/salt-kubebin/blob/master/docs/helm.md) |                                                              |
