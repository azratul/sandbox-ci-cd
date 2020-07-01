#!/bin/sh

export DNS=magi-system.com
export DNS_IP=192.168.121.10
export DEBIAN_FRONTEND=noninteractive

# CORE PACKAGES INSTALLATION
apt -y install curl apt-transport-https vim openssh-server ca-certificates resolvconf #postfix
cp /tmp/*.crt /usr/local/share/ca-certificates/
update-ca-certificates

# GITLAB INSTALLATION
printf "search ${DNS}\nnameserver ${DNS_IP}\n" >> /etc/resolvconf/resolv.conf.d/head
resolvconf -u
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
EXTERNAL_URL="http://gitlab.${DNS}" apt-get -y install gitlab-ce
