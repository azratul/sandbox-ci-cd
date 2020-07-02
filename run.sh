#!/bin/sh
PWDP=${PWD}

cd ${PWDP}/dns && vagrant up && mv portus.crt ../certs/
cd ${PWDP}/microk8s && vagrant up
cd ${PWDP}/gitlab && vagrant up
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
