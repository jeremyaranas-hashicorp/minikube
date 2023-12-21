#!/usr/bin/env bash

source ../main/common.sh

kubectl apply -f ../manifests/postgres-app-pod-02.yaml 

# Create service account and clusterrolebindings for postgres pod
create_postgres-service-account