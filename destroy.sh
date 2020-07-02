#!/bin/sh
PWDP=${PWD}

cd ${PWDP}/dns && vagrant destroy
cd ${PWDP}/microk8s && vagrant destroy
cd ${PWDP}/gitlab && vagrant destroy

echo "*****************************************"
echo "*               Destroyed!              *"
echo "*****************************************"
