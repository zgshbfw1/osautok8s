# 生成 CA
jsondir=/k8sInstallV11013/masterInstall/config/masterConf/ssl/
outdir=/k8sInstallV11013/masterInstall/config/masterConf/ssl/output/

cfssl gencert --initca=true ${jsondir}k8s-root-ca-csr.json | cfssljson --bare master-ca

# 依次生成其他组件证书
for targetName in master-admin master-apiserver kube-proxy; do
    cfssl gencert --ca ${outdir}master-ca.pem --ca-key ${outdir}master-ca-key.pem --config ${jsondir}k8s-gencert.json --profile kubernetes ${jsondir}${targetName}-csr.json | cfssljson --bare $targetName
done

# 地址默认为 127.0.0.1:6443
# 如果在 master 上启用 kubelet 请在生成后的 kubeconfig 中
# 修改该地址为 当前MASTER_IP:6443
KUBE_APISERVER="https://127.0.0.1:6443"
BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
echo "Tokne: ${BOOTSTRAP_TOKEN}"

# 不要质疑 system:bootstrappers 用户组是否写错了，有疑问请参考官方文档
# https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping/
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:bootstrappers"
EOF


exit 1




echo "Create kubelet bootstrapping kubeconfig..."
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=k8s-root-ca.pem \
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
  --certificate-authority=k8s-root-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
