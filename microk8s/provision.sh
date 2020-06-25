#!/bin/sh

export GITLAB=121.11
export DNS=magi-system.com
export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/snap/bin:/usr/shell-scripts

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
echo "***********************************************"
echo "*          INSTALLING CORE PACKAGES           *"
echo "***********************************************"
apt -y install snapd git ufw curl apt-transport-https vim openconnect bind9 bind9utils bind9-doc resolvconf
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

# CHANGING SETTINGS IN CORE DNS & API SERVER
echo "***********************************************"
echo "*       CHANGING  CORE DNS & API SERVER       *"
echo "***********************************************"
sed -i 's/--insecure-port=0/&\n--allow-privileged=true/g'  /var/snap/microk8s/current/args/kube-apiserver
microk8s.kubectl get -n kube-system configmaps/coredns -o yaml | \
sed '0,/forward ..*$/s//forward . \/etc\/resolv.conf /' | \
microk8s.kubectl replace -n kube-system -f -

# BASICS BIND9 SETTINGS. YOU'LL HAVE TO CHANGED IT ACCORDING TO YOUR NEEDS
echo "***********************************************"
echo "*            INSTALLING DNS SERVER            *"
echo "***********************************************"
sed 's/OPTIONS.*bind/& -4/g' /etc/default/bind9
cp /etc/bind/db.local /etc/bind/forward.${DNS}
cp /etc/bind/db.127 /etc/bind/reverse.${DNS}
cp /vagrant/named.conf.local /etc/bind/named.conf.local
cp /vagrant/named.conf.options /etc/bind/named.conf.options
sed -i "s/localhost/kubernetes.${DNS}/g" /etc/bind/forward.${DNS}
sed -i "s/localhost/${DNS}/g" /etc/bind/reverse.${DNS}
sed -i "s/\tIN\tNS\t/&kubernetes./g" /etc/bind/reverse.${DNS}
IP=$(ip a | grep ens | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/" | sed 's/\///g')
OCTET12=$(echo ${IP} | sed 's/\.[0-9]\+\.[0-9]\+$//')
OCTET34=$(echo ${IP} | sed 's/[0-9]\+\.[0-9]\+\.//')
printf "kubernetes\tIN\tA\t${IP}\n" >> /etc/bind/forward.${DNS}
printf "gitlab\tIN\tA\t${OCTET12}.${GITLAB}\n" >> /etc/bind/forward.${DNS}
printf "kubernetes\tIN\tA\t${IP}\n" >> /etc/bind/reverse.${DNS}
printf "${OCTET34}\tIN\tPTR\tkubernetes.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${GITLAB}\tIN\tPTR\tgitlab.${DNS}.\n" >> /etc/bind/reverse.${DNS}
sed -i "s/localhost:32000/kubernetes.${DNS}:32000/g" /var/snap/microk8s/current/args/containerd.toml
sed -i "s/localhost:32000/kubernetes.${DNS}:32000/g" /var/snap/microk8s/current/args/containerd-template.toml
printf "search ${DNS}\nnameserver ${IP}\n" >> /etc/resolvconf/resolv.conf.d/head

echo "*******************************************************************"
echo "*                           DONE, BUT...                          *"
echo "*******************************************************************"
echo "*                                                                 *"
echo "* IF YOU WANT TO ADD ANOTHER DNS, JUST DO SOMETHING LIKE THIS:    *"
echo "* SOME SETTINGS INTO THIS FILES                                   *"
echo "*  - /etc/bind/forward.<YOUR>.<DNS>                               *"
echo "* SOMETHING LIKE THIS: gitlab IN A <YOUR.GIT.LAB.IP>              *"
echo "*  - /etc/bind/reverse.<YOUR>.<DNS>                               *"
echo "* SOMETHING LIKE THIS: <255>.<255> IN   PTR  gitlab.<YOUR>.<DNS>. *"
echo "* AND RESTART THE SERVICE: sudo systemctl restart bind9           *"
echo "*                                                                 *"
echo "*******************************************************************"