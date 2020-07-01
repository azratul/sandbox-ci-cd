#!/bin/sh
mkdir certs
rm certs/portus.crt
cd dns && vagrant up && mv portus.crt ../certs/ && cd ..
cd microk8s && vagrant up && cd ..
cd gitlab && vagrant up && cd ..
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
