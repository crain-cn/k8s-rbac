#!/bin/env bash
set -ex
# 需要修改为对应集群名称，通过cat /etc/kubernetes/kubelet.conf中context下的cluster确定
# 集群kube-apiserver的地址
CLUSTER_URL=$( kubectl config view -o jsonpath='{.clusters[0].cluster.server}' )
PWD=`pwd`
K8S_CA_CRT="${PWD}/ca.crt"
# 自己k8s集群的ca，根据实际情况修改
K8S_CA_PEM="/etc/kubernetes/pki/ca.pem"
K8S_CA_PEM_KEY="/etc/kubernetes/pki/ca-key.pem"

# ⽤户名称，和步骤1中的保持一致
USER=istiossh
CLUSTER=${CLUSTER_URL}

SA_SECRET=$( kubectl get sa default -o jsonpath='{.secrets[0].name}' )
BEARER_TOKEN=$( kubectl get secrets  $SA_SECRET -o jsonpath='{.data.token}' | base64 -d )
kubectl get secrets $SA_SECRET -o jsonpath='{.data.ca\.crt}' | base64 -d > ./ca.crt

# 签发证书，注意istiossh-csr.json 中的 CN 值要和 ${USER} 参数保持一致
cfssl gencert -ca=${K8S_CA_PEM} -ca-key=${K8S_CA_PEM_KEY} -config=ca-config.json -profile=kubernetes ./istiossh-csr.json | cfssljson -bare ${USER}

# 设定权限上下⽂
kubectl config set-cluster ${CLUSTER} \
--certificate-authority=${K8S_CA_CRT} \
--embed-certs=true \
--server=${CLUSTER_URL} \
--kubeconfig=${USER}.kubeconfig

kubectl config set-credentials ${USER} \
--client-certificate=${PWD}/${USER}.pem \
--client-key=${PWD}/${USER}-key.pem \
--embed-certs=true \
--kubeconfig=${USER}.kubeconfig

kubectl config --kubeconfig=${USER}.kubeconfig \
    set-context registry \
    --cluster=${CLUSTER} \
    --user=${USER}

kubectl config --kubeconfig=${USER}.kubeconfig \
    use-context registry

echo "kubeconfig written to file \"${USER}.kubeconfig\""

cat <<EOF | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2021-12-27T05:51:05Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:${USER}
rules:
  - apiGroups:
      - "*"
    resources:
      - "*"
    verbs:
      - "*"
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:${USER}
roleRef:
  kind: ClusterRole
  name: system:${USER}
  apiGroup: rbac.authorization.k8s.io
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${USER}
  namespace: default
EOF

#测试
kubectl --kubeconfig=${PWD}/${USER}.kubeconfig