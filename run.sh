#!/bin/sh

cd dns && vagrant up && cd ..
cd microk8s && vagrant up && cd ..
cd gitlab && vagrant up && cd ..
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
