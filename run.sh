.#!/bin/sh

rm certs/portus.crt
cd ${PWD}/dns && vagrant up && mv portus.crt ../certs/
cd ${PWD}/microk8s && vagrant up
cd ${PWD}/gitlab && vagrant up
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
