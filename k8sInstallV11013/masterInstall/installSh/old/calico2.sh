#!/bin/sh
etcd1="10.129.55.61"
etcd2="10.129.55.65"
etcd3="10.129.55.155"


cyml=/k8sInstallV11013/masterInstall/baseYaml/calico/calico.yaml

ETCD_CERT=`cat /etc/etcd/ssl/etcd-server.pem | base64 | tr -d '\n'`
ETCD_KEY=`cat /etc/etcd/ssl/etcd-server-key.pem | base64 | tr -d '\n'`
ETCD_CA=`cat /etc/etcd/ssl/etcd-ca.pem | base64 | tr -d '\n'`
ETCD_ENDPOINTS="https://${etcd1}:2379,https://${etcd2}:2379,https://${etcd3}:2379"
###\cp calico.example.yaml ${cyml}

sed -i "s@.*etcd_endpoints:.*@\ \ etcd_endpoints:\ \"${ETCD_ENDPOINTS}\"@gi" ${cyml}

sed -i "s@.*etcd-cert:.*@\ \ etcd-cert:\ ${ETCD_CERT}@gi" ${cyml}
sed -i "s@.*etcd-key:.*@\ \ etcd-key:\ ${ETCD_KEY}@gi" ${cyml}
sed -i "s@.*etcd-ca:.*@\ \ etcd-ca:\ ${ETCD_CA}@gi" ${cyml}

sed -i 's@.*etcd_ca:.*@\ \ etcd_ca:\ "/calico-secrets/etcd-ca"@gi' ${cyml}
sed -i 's@.*etcd_cert:.*@\ \ etcd_cert:\ "/calico-secrets/etcd-cert"@gi' ${cyml}
sed -i 's@.*etcd_key:.*@\ \ etcd_key:\ "/calico-secrets/etcd-key"@gi' ${cyml}
