#!/bin/sh

KUBE_APISERVER="https://127.0.0.1:6443"
BOOTSTRAP_TOKEN=0907f0bdd69d8c9b2c97e1906614cc5f
conf=/etc/kubernetes/ssl/

echo "Tokne: ${BOOTSTRAP_TOKEN}"

cd /opt/
# 不要质疑 system:bootstrappers 用户组是否写错了，有疑问请参考官方文档
# https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping/
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:bootstrappers"
EOF

echo "Create kubelet bootstrapping kubeconfig..."
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=${conf}master-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

echo "Create kube-proxy kubeconfig..."
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=${conf}master-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=${conf}kube-proxy.pem \
  --client-key=${conf}kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
