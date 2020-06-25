#!/bin/sh

export KUBERNETES=192.168.121.10
export DNS=magi-system.com
export DEBIAN_FRONTEND=noninteractive

# CORE PACKAGES INSTALLATION
apt -y install curl apt-transport-https vim openssh-server ca-certificates resolvconf #postfix

# GITLAB INSTALLATION
printf "search ${DNS}\nnameserver ${KUBERNETES}\n" >> /etc/resolvconf/resolv.conf.d/head
resolvconf -u
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
EXTERNAL_URL="http://gitlab.${DNS}" apt-get -y install gitlab-ce