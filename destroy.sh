#!/bin/sh

cd ${PWD}/dns && vagrant destroy
cd ${PWD}/microk8s && vagrant destroy
cd ${PWD}/gitlab && vagrant destroy
echo "*****************************************"
echo "*               Destroyed!              *"
echo "*****************************************"
