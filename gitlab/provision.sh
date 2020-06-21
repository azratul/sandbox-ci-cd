#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
# CORE PACKAGES INSTALLATION
apt -y install curl apt-transport-https vim openssh-server ca-certificates #postfix

# GITLAB INSTALLATION
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
EXTERNAL_URL="http://gitlab.magi-system.com" apt-get -y install gitlab-ce
