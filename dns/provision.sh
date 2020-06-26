#!/bin/sh

export GITLAB=121.11
export KUBERNETES=121.12
export IP=$(ip a | grep ens6 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/" | sed 's/\///g')
export DNS=magi-system.com
export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/snap/bin
export FINAL_USER=vagrant

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
echo "***********************************************"
echo "*          INSTALLING CORE PACKAGES           *"
echo "***********************************************"
apt -y install snapd git ufw curl apt-transport-https vim bind9 bind9utils bind9-doc resolvconf
snap install core
snap install docker
ufw allow 53
ufw allow 5000

# MODIFYING PRINCIPAL USER'S PERMISSIONS
groupadd docker
usermod -aG docker $FINAL_USER
snap disable docker
snap enable docker

# BASICS BIND9 SETTINGS. YOU'LL HAVE TO CHANGED IT ACCORDING TO YOUR NEEDS
echo "***********************************************"
echo "*            INSTALLING DNS SERVER            *"
echo "***********************************************"
sed 's/OPTIONS.*bind/& -4/g' /etc/default/bind9
cp /etc/bind/db.local /etc/bind/forward.${DNS}
cp /etc/bind/db.127 /etc/bind/reverse.${DNS}
cp /vagrant/named.conf.local /etc/bind/named.conf.local
cp /vagrant/named.conf.options /etc/bind/named.conf.options
sed -i "s/localhost/dns.${DNS}/g" /etc/bind/forward.${DNS}
sed -i 's/@\tIN\tA/; &/g' /etc/bind/forward.magi-system.com
sed -i "s/localhost/${DNS}/g" /etc/bind/reverse.${DNS}
sed -i "s/\tIN\tNS\t/&dns./g" /etc/bind/reverse.${DNS}
sed -i 's/1\.0\.0\tIN/; &/g' /etc/bind/reverse.magi-system.com
OCTET1=$(echo ${IP%%.*})
OCTET2=$(echo ${IP}|cut -d "." -f 2)
OCTET3=$(echo ${IP}|cut -d "." -f 3)
OCTET4=$(echo ${IP##*.})
GITLAB1=$(echo ${GITLAB%%.*})
GITLAB2=$(echo ${GITLAB##*.})
KUBERNETES1=$(echo ${KUBERNETES%%.*})
KUBERNETES2=$(echo ${KUBERNETES##*.})
printf "dns\tIN\tA\t${IP}\n" >> /etc/bind/forward.${DNS}
printf "docker\tIN\tA\t${IP}\n" >> /etc/bind/forward.${DNS}
printf "gitlab\tIN\tA\t${OCTET1}.${OCTET2}.${GITLAB1}.${GITLAB2}\n" >> /etc/bind/forward.${DNS}
printf "kubernetes\tIN\tA\t${OCTET1}.${OCTET2}.${KUBERNETES1}.${KUBERNETES2}\n" >> /etc/bind/forward.${DNS}
printf "dns\tIN\tA\t${IP}\n" >> /etc/bind/reverse.${DNS}
printf "${OCTET4}.${OCTET3}\tIN\tPTR\tdns.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${GITLAB2}.${GITLAB1}\tIN\tPTR\tgitlab.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${KUBERNETES2}.${KUBERNETES1}\tIN\tPTR\tkubernetes.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${OCTET4}.${OCTET3}\tIN\tPTR\tdocker.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "search ${DNS}\nnameserver ${IP}\n" >> /etc/resolvconf/resolv.conf.d/head
