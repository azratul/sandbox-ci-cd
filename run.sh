#!/bin/sh
rm certs/*.crt
cd dns && vagrant up && mv *.crt ../certs/ && cd ..
cd microk8s && vagrant up && cd ..
cd gitlab && vagrant up && cd ..
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
