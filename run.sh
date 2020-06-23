#!/bin/sh

cd microk8s && vagrant up && cd ..
cd gitlab && vagrant up && cd ..
echo "*****************************************"
echo "*             Up & Running!             *"
echo "*****************************************"
