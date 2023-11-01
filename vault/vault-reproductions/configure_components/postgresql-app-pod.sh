#!/usr/bin/env bash

kubectl apply -f ../manifests/postgres-config.yaml
kubectl apply -f ../manifests/postgres-pvc-pv.yaml
kubectl apply -f ../manifests/postgres-deployment.yaml 
kubectl apply -f ../manifests/postgres-service.yaml

# Create service account and clusterrolebindings for postgres pod
source ../main/common.sh
create_postgres-service-account
create_postgres-token-review-clusterrolebindings