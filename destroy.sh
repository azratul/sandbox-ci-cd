#!/bin/sh

cd microk8s && vagrant destroy && cd ..
cd gitlab && vagrant destroy && cd ..
echo "*****************************************"
echo "*               Destroyed!              *"
echo "*****************************************"
