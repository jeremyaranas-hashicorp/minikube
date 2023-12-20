#!/usr/bin/env bash

source ../main/common.sh
login_to_vault

kubectl apply -f ../manifests/postgres-app-pod-02-tls.yaml 

# Create service account and clusterrolebindings for postgres pod
create_postgres-service-account