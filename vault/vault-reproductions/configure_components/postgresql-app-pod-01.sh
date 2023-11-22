#!/usr/bin/env bash

source ../main/common.sh

kubectl exec -ti -n vault vault-0 -- vault secrets enable database 

kubectl apply -f ../manifests/postgres-app-pod-01.yaml

