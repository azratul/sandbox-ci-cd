#!/bin/bash

# ACTUAL IP
IP=$(ip a | grep ens | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/" | sed 's/\///g')

# API URL
API_URL=$(microk8s.kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}')
API_URL=${API_URL/127.0.0.1/$IP}

# CA certificate
CA_CERT=$(microk8s.kubectl get secret $(microk8s.kubectl get secrets | grep -o "default-token-[a-zA-Z0-9]*") -o jsonpath="{['data']['ca\.crt']}" | base64 --decode)

# Token:
echo "apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: gitlab-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: gitlab-admin
  namespace: kube-system" > .gitlab-admin-service-account.yaml

microk8s.kubectl apply -f .gitlab-admin-service-account.yaml
TOKEN=$(microk8s.kubectl -n kube-system describe secret $(microk8s.kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}') | grep 'token:' | cut -d ' ' -f 7)

printf "Api URL: ${API_URL}\nCA Cert: ${CA_CERT}\nToken: ${TOKEN}" > .gitlab.conf

