#!/usr/bin/env bash

kubectl exec -ti -n vault vault-0 -- vault secrets enable database 
kubectl apply -f ../manifests/postgres-app-pod-v1.yaml