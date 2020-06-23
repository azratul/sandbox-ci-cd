#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/snap/bin:/usr/shell-scripts

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
echo "***********************************************"
echo "*          INSTALLING CORE PACKAGES           *"
echo "***********************************************"
apt -y install snapd git ufw curl apt-transport-https vim openconnect bind9 bind9utils bind9-doc
snap install core
snap install microk8s --classic
snap install docker
ufw allow in on cni0
ufw allow out on cni0
ufw default allow routed
ufw allow 53

# ENABLING PRINCIPAL K8S MODULES
echo "***********************************************"
echo "*         ENABLING KUBERNETES MODULES         *"
echo "***********************************************"
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
groupadd docker
usermod -aG docker $FINAL_USER
usermod -aG microk8s $FINAL_USER
snap disable docker
snap enable docker

# BASICS BIND9 SETTINGS. YOU'LL HAVE TO CHANGED IT ACCORDING TO YOUR NEEDS
echo "***********************************************"
echo "*            INSTALLING DNS SERVER            *"
echo "***********************************************"
sed 's/OPTIONS.*bind/& -4/g' /etc/default/bind9
cp /etc/bind/db.local /etc/bind/forward.magi-system.com
cp /etc/bind/db.127 /etc/bind/reverse.magi-system.com
cp /vagrant/named.conf.local /etc/bind/named.conf.local
cp /vagrant/named.conf.options /etc/bind/named.conf.options
sed -i 's/localhost/kubernetes.magi-system.com/g' /etc/bind/forward.magi-system.com
sed -i 's/localhost/magi-system.com/g' /etc/bind/reverse.magi-system.com
IP=$(ip a | grep ens | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/" | sed 's/\///g')
printf "kubernetes\tIN\tA\t${IP}" >> /etc/bind/forward.magi-system.com
printf "kubernetes\tIN\tA\t${IP}" >> /etc/bind/reverse.magi-system.com

echo "*******************************************************************"
echo "*                           DONE, BUT...                          *"
echo "*******************************************************************"
echo " IF YOU WANT A FULLY FUNCTIONAL DNS SERVER, YOU'LL NEED TO ADD"
echo " SOME SETTINGS INTO THIS FILES"
echo "  - /etc/bind/forward.magi-system.com"
echo " SOMETHING LIKE THIS: gitlab IN A <GITLAB_IP>"
echo "  - /etc/bind/reverse.magi-system.com"
echo " SOMETHING LIKE THIS: <255>.<255> IN PTR kubernetes.magi-system.com"
echo " AND LIKE THIS: <255>.<255> IN PTR gitlab.magi-system.com"