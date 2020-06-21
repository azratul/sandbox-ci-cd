#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/snap/bin:/usr/shell-scripts

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
apt -y install snapd git ufw curl apt-transport-https vim openconnect
snap install core
snap install microk8s --classic
snap install docker
ufw allow in on cni0
ufw allow out on cni0
ufw default allow routed

# ENABLING PRINCIPAL K8S MODULES
microk8s.status --wait-ready
microk8s.enable dashboard
microk8s.enable dns
microk8s.enable registry
microk8s.enable ingress
microk8s.enable storage
microk8s.enable helm3
microk8s.enable metrics-server

# ENV VARS TO DEFINE SOME OF THE BASICS
export OPENFAAS=$(head -c 12 /dev/urandom | shasum | cut -d " " -f1)
export FINAL_USER=vagrant

# EXTRACTING IMPORTANT INFO TO THE HOST MACHINE
microk8s.kubectl config view --raw > /vagrant/.kube-config
echo "openfaas-token=$OPENFAAS" > /vagrant/.tokens

# INSTALLATION OF FAAS-NETES, OPENFAAS AND FAAS-CLI
microk8s.kubectl -n kube-system describe secret $K8TOKEN
microk8s.kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
microk8s.kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$OPENFAAS"
git clone https://github.com/openfaas/faas-netes
microk8s.kubectl apply -f ./faas-netes/yaml && rm -rf faas-netes
curl -sSL https://cli.openfaas.com | sh
faas-cli completion --shell bash > /etc/bash_completion.d/faas-cli

# MODIFYING PRINCIPAL USER'S PERMISSIONS
groupadd docker
usermod -aG docker $FINAL_USER
usermod -aG microk8s $FINAL_USER
snap disable docker
snap enable docker
