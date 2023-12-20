#!/usr/bin/env bash

kubectl apply -f ../manifests/postgres-app-pod-02-tls.yaml 

# Create service account and clusterrolebindings for postgres pod
source ../main/common.sh
create_postgres-service-account
