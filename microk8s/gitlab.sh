#!/bin/sh

# API URL
API_URL=$(microk8s.kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}')

# CA certificate
CA_CERT=$(microk8s.kubectl get secret $(microk8s.kubectl get secrets | grep -o "default-token-[a-zA-Z0-9]*") -o jsonpath="{['data']['ca\.crt']}" | base64 --decode)

# Token:
echo "apiVersion: v1\n
kind: ServiceAccount\n
metadata:\n
  name: gitlab-admin\n
  namespace: kube-system\n
---\n
apiVersion: rbac.authorization.k8s.io/v1beta1\n
kind: ClusterRoleBinding\n
metadata:\n
  name: gitlab-admin\n
roleRef:\n
  apiGroup: rbac.authorization.k8s.io\n
  kind: ClusterRole\n
  name: cluster-admin\n
subjects:\n
- kind: ServiceAccount\n
  name: gitlab-admin\n
  namespace: kube-system" > .gitlab-admin-service-account.yaml

microk8s.kubectl apply -f .gitlab-admin-service-account.yaml
TOKEN=$(microk8s.kubectl -n kube-system describe secret $(microk8s.kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}') | grep 'token:' | cut -d ' ' -f 7)

echo "Api URL: ${API_URL}\nCA Cert: ${CA_CERT}\nToken: ${TOKEN}" > .gitlab.conf

