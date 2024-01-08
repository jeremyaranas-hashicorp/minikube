#!/usr/bin/env bash

source ../main/common.sh

kubectl apply -f ../manifests/postgres-app-pod-03_tls.yaml 

# Create service account and clusterrolebindings for postgres pod
create_postgres-service-account