#!/bin/sh

export GITLAB=121.11
export DNS_IP=192.168.121.10
export DOCKER=docker.magi-system.com
export DNS=magi-system.com
export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/snap/bin:/usr/shell-scripts
export FINAL_USER=vagrant

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
echo "***********************************************"
echo "*          INSTALLING CORE PACKAGES           *"
echo "***********************************************"
apt -y install snapd git ufw curl apt-transport-https vim openconnect resolvconf
snap install core
snap install microk8s --classic
ufw allow in on cni0
ufw allow out on cni0
ufw default allow routed

# ENABLING PRINCIPAL K8S MODULES
echo "***********************************************"
echo "*         ENABLING KUBERNETES MODULES         *"
echo "***********************************************"
microk8s.status --wait-ready
microk8s.enable dashboard
microk8s.enable dns
microk8s.enable ingress
microk8s.enable storage
microk8s.enable helm3
microk8s.enable metrics-server

# ENV VARS TO DEFINE SOME OF THE BASICS
export OPENFAAS=$(head -c 12 /dev/urandom | shasum | cut -d " " -f1)

# EXTRACTING IMPORTANT INFO TO THE HOST MACHINE
microk8s.kubectl config view --raw > /vagrant/.kube-config
echo "openfaas-token=$OPENFAAS" > /vagrant/.tokens

# INSTALLATION OF FAAS-NETES, OPENFAAS AND FAAS-CLI
echo "***********************************************"
echo "*             INSTALLING OPENFAAS             *"
echo "***********************************************"
microk8s.kubectl -n kube-system describe secret $K8TOKEN
microk8s.kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
microk8s.kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$OPENFAAS"
git clone https://github.com/openfaas/faas-netes
microk8s.kubectl apply -f ./faas-netes/yaml && rm -rf faas-netes
curl -sSL https://cli.openfaas.com | sh

# INSTALLATION BASH COMPLETION FOR FAAS-CLI & KUBECTL
echo "***********************************************"
echo "*          INSTALLING BASH COMPLETION         *"
echo "***********************************************"
faas-cli completion --shell bash > /etc/bash_completion.d/faas-cli
microk8s.kubectl completion bash > /etc/bash_completion.d/kubectl
# MODIFYING PRINCIPAL USER'S PERMISSIONS
usermod -aG microk8s $FINAL_USER

# CHANGING SETTINGS IN CORE DNS & API SERVER
echo "***********************************************"
echo "*       CHANGING  CORE DNS & API SERVER       *"
echo "***********************************************"
sed -i 's/--insecure-port=0/&\n--allow-privileged=true/g' /var/snap/microk8s/current/args/kube-apiserver
microk8s.kubectl get -n kube-system configmaps/coredns -o yaml | \
sed '0,/forward ..*$/s//forward . \/etc\/resolv.conf /' | \
microk8s.kubectl replace -n kube-system -f -

# BASICS BIND9 SETTINGS. YOU'LL HAVE TO CHANGED IT ACCORDING TO YOUR NEEDS
echo "***********************************************"
echo "*            INSTALLING DNS SERVER            *"
echo "***********************************************"
sed -i "s/localhost:32000/${DOCKER}:32000/g" /var/snap/microk8s/current/args/containerd.toml
sed -i "s/localhost:32000/${DOCKER}:32000/g" /var/snap/microk8s/current/args/containerd-template.toml
printf "search ${DNS}\nnameserver ${DNS_IP}\n" >> /etc/resolvconf/resolv.conf.d/head
